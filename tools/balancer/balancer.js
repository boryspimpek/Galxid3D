const STORAGE_KEY = 'galaxid3d_balancer';

function getDefaultGameData() {
    return {
        generators: [
            { id: "generator_t1", name: "Generator T1", maxEnergy: 300, regen: 30 },
            { id: "generator_t2", name: "Generator T2", maxEnergy: 400, regen: 40 }
        ],
        weapons: [
            { id: "laser_plazmowy_t1", name: "Laser Plazmowy T1", generatorId: "generator_t1", dmg: 10, cooldown: 0.2, cost: 10, dps: 50 },
            { id: "ciezkie_dzialo_t2", name: "Ciężkie Działo T2", generatorId: "generator_t2", dmg: 60, cooldown: 0.4, cost: 25, dps: 150 }
        ],
        enemies: [
            { id: "mieso_armatnie_dron", name: "Mięso Armatnie (Dron)", weaponAnchor: "laser_plazmowy_t1", ttk: 0.0, hp: 10, playerHp: 100, ttd: 20, dps: 5, attackCooldown: 1.0, projectileDmg: 5, shotsToKill: 20, shotsToKillAnchor: 1, threatPoints: 0 },
            { id: "standardowy_mysliwiec", name: "Standardowy Myśliwiec", weaponAnchor: "laser_plazmowy_t1", ttk: 0.5, hp: 25, playerHp: 100, ttd: 5, dps: 20, attackCooldown: 0.5, projectileDmg: 10, shotsToKill: 10, shotsToKillAnchor: 3, threatPoints: 10 }
        ]
    };
}

let gameData = getDefaultGameData();
let currentSimEnergy = 300;
let editingGeneratorId = null;
let editingWeaponId = null;
let editingEnemyId = null;
let pendingFormRestore = null;

function slugifyId(name) {
    return name.toLowerCase().replace(/[^a-z0-9]/g, "_");
}

function ensureEnemyIds() {
    gameData.enemies.forEach(enemy => {
        if (!enemy.id) {
            let id = slugifyId(enemy.name);
            let suffix = 2;
            while (gameData.enemies.some(other => other !== enemy && other.id === id)) {
                id = `${slugifyId(enemy.name)}_${suffix++}`;
            }
            enemy.id = id;
        }

        if (enemy.playerHp == null) enemy.playerHp = 100;
        if (enemy.ttd == null) enemy.ttd = enemy.dps > 0 ? enemy.playerHp / enemy.dps : 4;
        if (enemy.attackCooldown == null) {
            enemy.attackCooldown = enemy.projectileDmg && enemy.dps > 0
                ? enemy.projectileDmg / enemy.dps
                : 0.5;
        }
        if (enemy.ttd <= 0) {
            enemy.dps = 0;
            enemy.projectileDmg = enemy.playerHp;
            enemy.shotsToKill = 1;
            enemy.instantKill = true;
        } else {
            enemy.dps = enemy.playerHp / enemy.ttd;
            enemy.projectileDmg = enemy.dps * enemy.attackCooldown;
            enemy.shotsToKill = enemy.projectileDmg > 0
                ? Math.ceil(enemy.playerHp / enemy.projectileDmg)
                : 0;
            enemy.instantKill = false;
        }

        if (enemy.shotsToKillAnchor == null) {
            const anchor = gameData.weapons.find(w => w.id === enemy.weaponAnchor);
            enemy.shotsToKillAnchor = anchor && enemy.hp != null
                ? (enemy.hp <= anchor.dmg ? 1 : Math.ceil(enemy.hp / anchor.dmg))
                : 0;
        }
    });
}

function isValidGameData(data) {
    return data
        && Array.isArray(data.generators)
        && Array.isArray(data.weapons)
        && Array.isArray(data.enemies);
}

function collectFormState() {
    return {
        editingGeneratorId,
        editingWeaponId,
        editingEnemyId,
        generator: {
            name: document.getElementById('g-name').value,
            maxEnergy: parseFloat(document.getElementById('g-max-energy').value),
            regen: parseFloat(document.getElementById('g-regen').value)
        },
        weapon: {
            name: document.getElementById('w-name').value,
            generatorId: document.getElementById('w-generator-select').value,
            dmg: parseFloat(document.getElementById('w-dmg').value),
            cooldown: parseFloat(document.getElementById('w-cooldown').value),
            cost: parseFloat(document.getElementById('w-cost').value)
        },
        enemy: {
            name: document.getElementById('e-name').value,
            weaponAnchor: document.getElementById('e-weapon-select').value,
            ttk: parseFloat(document.getElementById('e-ttk').value),
            playerHp: parseFloat(document.getElementById('e-player-hp').value),
            ttd: parseFloat(document.getElementById('e-ttd').value),
            attackCooldown: parseFloat(document.getElementById('e-attack-cd').value)
        }
    };
}

function applyFormState(form) {
    if (!form) return;

    editingGeneratorId = form.editingGeneratorId ?? null;
    editingWeaponId = form.editingWeaponId ?? null;
    editingEnemyId = form.editingEnemyId ?? null;

    if (form.generator) {
        document.getElementById('g-name').value = form.generator.name ?? '';
        document.getElementById('g-max-energy').value = form.generator.maxEnergy ?? 300;
        document.getElementById('g-regen').value = form.generator.regen ?? 30;
    }

    if (form.weapon) {
        document.getElementById('w-name').value = form.weapon.name ?? '';
        document.getElementById('w-dmg').value = form.weapon.dmg ?? 10;
        document.getElementById('w-cooldown').value = form.weapon.cooldown ?? 0.2;
        document.getElementById('w-cost').value = form.weapon.cost ?? 10;
    }

    if (form.enemy) {
        document.getElementById('e-name').value = form.enemy.name ?? '';
        document.getElementById('e-ttk').value = form.enemy.ttk ?? 0.5;
        document.getElementById('e-player-hp').value = form.enemy.playerHp ?? 100;
        document.getElementById('e-ttd').value = form.enemy.ttd ?? 4;
        document.getElementById('e-attack-cd').value = form.enemy.attackCooldown ?? 0.1;
    }

    return form;
}

function persistState() {
    try {
        const payload = {
            gameData,
            form: collectFormState()
        };
        localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    } catch (e) {
        console.warn('Nie udało się zapisać ustawień:', e);
    }
}

function loadState() {
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (!raw) return false;

        const saved = JSON.parse(raw);
        if (isValidGameData(saved.gameData)) {
            gameData = saved.gameData;
            ensureEnemyIds();
            return saved.form ?? true;
        }
        if (isValidGameData(saved)) {
            gameData = saved;
            ensureEnemyIds();
            return true;
        }
    } catch (e) {
        console.warn('Nie udało się wczytać ustawień:', e);
    }
    return false;
}

function importFromJson() {
    try {
        const parsed = JSON.parse(document.getElementById('json-preview').value);
        const data = isValidGameData(parsed) ? parsed : parsed.gameData;

        if (!isValidGameData(data)) {
            alert('Nieprawidłowy JSON. Oczekiwane pola: generators, weapons, enemies.');
            return;
        }

        gameData = data;
        ensureEnemyIds();
        editingGeneratorId = null;
        editingWeaponId = null;
        editingEnemyId = null;
        updateTables();
        persistState();
    } catch (e) {
        alert('Błąd parsowania JSON: ' + e.message);
    }
}

function downloadJson() {
    const blob = new Blob([JSON.stringify(gameData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'balancer_export.json';
    link.click();
    URL.revokeObjectURL(url);
}

function resetAllData() {
    if (!confirm('Przywrócić domyślne dane i wyczyścić zapis w przeglądarce?')) return;

    localStorage.removeItem(STORAGE_KEY);
    gameData = getDefaultGameData();
    newGeneratorForm();
    newWeaponForm();
    newEnemyForm();
    updateTables();
}

function getGeneratorById(id) {
    return gameData.generators.find(g => g.id === id);
}

function getWeaponById(id) {
    return gameData.weapons.find(w => w.id === id);
}

function getEnemyById(id) {
    return gameData.enemies.find(e => e.id === id);
}

function computeEnemyAttackStats() {
    const playerHp = parseFloat(document.getElementById('e-player-hp').value) || 100;
    const ttd = parseFloat(document.getElementById('e-ttd').value);
    const attackCooldown = parseFloat(document.getElementById('e-attack-cd').value);

    if (ttd <= 0) {
        return {
            playerHp,
            ttd: 0,
            dps: 0,
            attackCooldown,
            projectileDmg: playerHp,
            shotsToKill: 1,
            instantKill: true
        };
    }

    const dps = playerHp / ttd;
    const projectileDmg = dps * attackCooldown;
    const shotsToKill = projectileDmg > 0 ? Math.ceil(playerHp / projectileDmg) : 0;

    return { playerHp, ttd, dps, attackCooldown, projectileDmg, shotsToKill, instantKill: false };
}

function shotsToKillWithWeapon(hp, weapon) {
    if (!weapon || hp <= 0) return 0;
    return hp <= weapon.dmg ? 1 : Math.ceil(hp / weapon.dmg);
}

function computeEnemyDefenseStats(weaponAnchor, ttk, dps) {
    const anchorWeapon = gameData.weapons.find(w => w.id === weaponAnchor);
    if (!anchorWeapon) return { hp: 0, threatPoints: 0, shotsToKill: 0 };

    const hp = ttk <= 0 ? anchorWeapon.dmg : Math.round(anchorWeapon.dps * ttk);
    const threatPoints = Math.round(ttk * dps);
    const shotsToKill = shotsToKillWithWeapon(hp, anchorWeapon);
    return { hp, threatPoints, shotsToKill };
}

function buildEnemyRecord(weaponAnchor, enemyTtk) {
    const attack = computeEnemyAttackStats();
    const defense = computeEnemyDefenseStats(weaponAnchor, enemyTtk, attack.dps);

    return {
        playerHp: attack.playerHp,
        ttd: attack.ttd,
        dps: attack.dps,
        attackCooldown: attack.attackCooldown,
        projectileDmg: attack.projectileDmg,
        shotsToKill: attack.shotsToKill,
        instantKill: attack.instantKill,
        weaponAnchor,
        ttk: enemyTtk,
        hp: defense.hp,
        threatPoints: defense.threatPoints,
        shotsToKillAnchor: defense.shotsToKill
    };
}

function getSelectedWeaponGenerator() {
    const id = document.getElementById('w-generator-select').value;
    return getGeneratorById(id);
}

function resetSimEnergy() {
    const gen = getSelectedWeaponGenerator();
    currentSimEnergy = gen ? gen.maxEnergy : 0;
}

setInterval(() => {
    const gen = getSelectedWeaponGenerator();
    if (!gen) return;

    const cooldown = parseFloat(document.getElementById('w-cooldown').value);
    const cost = parseFloat(document.getElementById('w-cost').value);
    const maxEnergy = gen.maxEnergy;
    const regen = gen.regen;

    currentSimEnergy += regen * 0.1;
    const drainPerSecond = cost / cooldown;
    currentSimEnergy -= drainPerSecond * 0.1;

    if (currentSimEnergy > maxEnergy) currentSimEnergy = maxEnergy;
    if (currentSimEnergy < 0) currentSimEnergy = 0;

    const bar = document.getElementById('energy-bar');
    const pct = maxEnergy > 0 ? (currentSimEnergy / maxEnergy) * 100 : 0;
    bar.style.width = pct + '%';
    document.getElementById('energy-text').innerText = `⚡ ENERGIA GENERATORA: ${Math.round(currentSimEnergy)} / ${maxEnergy}`;
}, 100);

function updateGeneratorSliders() {
    document.getElementById('lbl-g-max').innerText = document.getElementById('g-max-energy').value;
    document.getElementById('lbl-g-regen').innerText = document.getElementById('g-regen').value;
    persistState();
}

function newGeneratorForm() {
    editingGeneratorId = null;
    document.getElementById('g-name').value = '';
    document.getElementById('g-max-energy').value = 300;
    document.getElementById('g-regen').value = 30;
    updateGeneratorSliders();
    highlightGeneratorRow();
    updateGeneratorFormMode();
    persistState();
}

function updateGeneratorFormMode() {
    const isEditing = !!editingGeneratorId;
    document.getElementById('btn-add-generator').hidden = isEditing;
    document.getElementById('btn-save-generator').hidden = !isEditing;

    const modeEl = document.getElementById('generator-form-mode');
    if (isEditing) {
        const gen = getGeneratorById(editingGeneratorId);
        modeEl.textContent = `Edycja: ${gen?.name ?? '—'}`;
        modeEl.className = 'form-mode form-mode-edit';
    } else {
        modeEl.textContent = 'Nowy generator';
        modeEl.className = 'form-mode form-mode-new';
    }
}

function loadGeneratorIntoForm(id) {
    const gen = getGeneratorById(id);
    if (!gen) return;

    editingGeneratorId = id;
    document.getElementById('g-name').value = gen.name;
    document.getElementById('g-max-energy').value = gen.maxEnergy;
    document.getElementById('g-regen').value = gen.regen;
    updateGeneratorSliders();
    highlightGeneratorRow();
    updateGeneratorFormMode();
    persistState();
}

function highlightGeneratorRow() {
    document.querySelectorAll('#generators-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingGeneratorId);
    });
}

function newWeaponForm() {
    editingWeaponId = null;
    document.getElementById('w-name').value = '';
    document.getElementById('w-dmg').value = 10;
    document.getElementById('w-cooldown').value = 0.2;
    document.getElementById('w-cost').value = 10;
    if (gameData.generators.length > 0) {
        document.getElementById('w-generator-select').value = gameData.generators[0].id;
    }
    updateSliders();
    onWeaponGeneratorChange();
    highlightWeaponRow();
    updateWeaponFormMode();
    persistState();
}

function updateWeaponFormMode() {
    const isEditing = !!editingWeaponId;
    document.getElementById('btn-add-weapon').hidden = isEditing;
    document.getElementById('btn-save-weapon').hidden = !isEditing;

    const modeEl = document.getElementById('weapon-form-mode');
    if (isEditing) {
        const weapon = getWeaponById(editingWeaponId);
        modeEl.textContent = `Edycja: ${weapon?.name ?? '—'}`;
        modeEl.className = 'form-mode form-mode-edit';
    } else {
        modeEl.textContent = 'Nowa broń';
        modeEl.className = 'form-mode form-mode-new';
    }
}

function loadWeaponIntoForm(id) {
    const weapon = getWeaponById(id);
    if (!weapon) return;

    editingWeaponId = id;
    document.getElementById('w-name').value = weapon.name;
    document.getElementById('w-dmg').value = weapon.dmg;
    document.getElementById('w-cooldown').value = weapon.cooldown;
    document.getElementById('w-cost').value = weapon.cost;

    const genSelect = document.getElementById('w-generator-select');
    if (weapon.generatorId && [...genSelect.options].some(o => o.value === weapon.generatorId)) {
        genSelect.value = weapon.generatorId;
    }

    updateSliders();
    onWeaponGeneratorChange();
    highlightWeaponRow();
    updateWeaponFormMode();
    persistState();
}

function highlightWeaponRow() {
    document.querySelectorAll('#weapons-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingWeaponId);
    });
}

function onWeaponGeneratorChange() {
    const gen = getSelectedWeaponGenerator();
    const info = document.getElementById('w-generator-info');
    if (gen) {
        info.innerText = `${gen.maxEnergy} max E · ${gen.regen} regen/s`;
    } else {
        info.innerText = 'Brak generatora — dodaj go w sekcji 1';
    }
    resetSimEnergy();
    sim();
}

function sim() {
    const gen = getSelectedWeaponGenerator();
    const dmg = parseFloat(document.getElementById('w-dmg').value);
    const cooldown = parseFloat(document.getElementById('w-cooldown').value);
    const cost = parseFloat(document.getElementById('w-cost').value);

    const dps = dmg / cooldown;
    const drain = cost / cooldown;

    document.getElementById('stat-dps').innerText = `${dps.toFixed(0)} DMG/s`;
    document.getElementById('stat-drain').innerText = `${drain.toFixed(0)} E/s`;

    if (!gen) {
        document.getElementById('stat-bilans').innerText = '—';
        document.getElementById('stat-depletion').innerText = '—';
        return;
    }

    const bilans = gen.regen - drain;
    const bilansEl = document.getElementById('stat-bilans');
    if (bilans >= 0) {
        bilansEl.innerText = `+${bilans.toFixed(0)} E/s (Nadwyżka)`;
        bilansEl.style.color = "#81c784";
        document.getElementById('stat-depletion').innerText = "Stabilny (Nieskończony ogień)";
        document.getElementById('stat-depletion').style.color = "#81c784";
    } else {
        bilansEl.innerText = `${bilans.toFixed(0)} E/s (Deficyt)`;
        bilansEl.style.color = "#e57373";
        const timeToDeplete = gen.maxEnergy / Math.abs(bilans);
        document.getElementById('stat-depletion').innerText = `${timeToDeplete.toFixed(1)} sekund`;
        document.getElementById('stat-depletion').style.color = "#ffb74d";
    }
}

function updateSliders() {
    document.getElementById('lbl-dmg').innerText = document.getElementById('w-dmg').value;
    document.getElementById('lbl-cd').innerText = parseFloat(document.getElementById('w-cooldown').value).toFixed(2) + 's';
    document.getElementById('lbl-cost').innerText = document.getElementById('w-cost').value;
    sim();
    calculateEnemyStats();
    persistState();
}

function newEnemyForm() {
    editingEnemyId = null;
    document.getElementById('e-name').value = '';
    document.getElementById('e-player-hp').value = 100;
    document.getElementById('e-ttd').value = 4;
    document.getElementById('e-attack-cd').value = 0.10;
    document.getElementById('e-ttk').value = 0.5;
    if (gameData.weapons.length > 0) {
        document.getElementById('e-weapon-select').value = gameData.weapons[0].id;
    }
    updateEnemySliders();
    highlightEnemyRow();
    updateEnemyFormMode();
    persistState();
}

function updateEnemyFormMode() {
    const isEditing = !!editingEnemyId;
    document.getElementById('btn-add-enemy').hidden = isEditing;
    document.getElementById('btn-save-enemy').hidden = !isEditing;

    const modeEl = document.getElementById('enemy-form-mode');
    if (isEditing) {
        const enemy = getEnemyById(editingEnemyId);
        modeEl.textContent = `Edycja: ${enemy?.name ?? '—'}`;
        modeEl.className = 'form-mode form-mode-edit';
    } else {
        modeEl.textContent = 'Nowy wróg';
        modeEl.className = 'form-mode form-mode-new';
    }
}

function loadEnemyIntoForm(id) {
    const enemy = getEnemyById(id);
    if (!enemy) return;

    editingEnemyId = id;
    document.getElementById('e-name').value = enemy.name;
    document.getElementById('e-ttk').value = enemy.ttk;
    document.getElementById('e-player-hp').value = enemy.playerHp ?? 100;
    document.getElementById('e-ttd').value = enemy.ttd ?? 4;
    document.getElementById('e-attack-cd').value = enemy.attackCooldown ?? 0.5;

    const weaponSelect = document.getElementById('e-weapon-select');
    if (enemy.weaponAnchor && [...weaponSelect.options].some(o => o.value === enemy.weaponAnchor)) {
        weaponSelect.value = enemy.weaponAnchor;
    }

    updateEnemySliders();
    highlightEnemyRow();
    updateEnemyFormMode();
    persistState();
}

function highlightEnemyRow() {
    document.querySelectorAll('#enemies-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingEnemyId);
    });
}

function updateEnemySliders() {
    const attack = computeEnemyAttackStats();

    document.getElementById('lbl-ttd').innerText = attack.ttd <= 0 ? '0s (1 strzał)' : attack.ttd.toFixed(2) + 's';
    document.getElementById('lbl-attack-cd').innerText = attack.attackCooldown.toFixed(2) + 's';
    document.getElementById('lbl-ttk').innerText = parseFloat(document.getElementById('e-ttk').value).toFixed(2) + 's';
    document.getElementById('stat-enemy-dps').innerText = attack.instantKill ? '1 strzał' : attack.dps.toFixed(1) + ' DPS';
    document.getElementById('stat-projectile-dmg').innerText = attack.projectileDmg.toFixed(1) + ' DMG';
    document.getElementById('stat-shots-to-kill').innerText = attack.shotsToKill;

    calculateEnemyStats();
    persistState();
}

function calculateEnemyStats() {
    const weaponId = document.getElementById('e-weapon-select').value;
    const ttk = parseFloat(document.getElementById('e-ttk').value);

    const anchorWeapon = gameData.weapons.find(w => w.id === weaponId);
    if (!anchorWeapon) return;

    let calculatedHp = 0;
    if (ttk <= 0) {
        calculatedHp = anchorWeapon.dmg;
    } else {
        calculatedHp = Math.round(anchorWeapon.dps * ttk);
    }

    document.getElementById('e-hp').value = calculatedHp;
    document.getElementById('stat-enemy-hp').innerText = calculatedHp + ' HP';
    document.getElementById('stat-shots-to-kill-enemy').innerText = shotsToKillWithWeapon(calculatedHp, anchorWeapon);
}

function addGenerator() {
    const name = document.getElementById('g-name').value.trim();
    if (!name) {
        alert('Podaj nazwę generatora.');
        return;
    }

    const maxEnergy = parseFloat(document.getElementById('g-max-energy').value);
    const regen = parseFloat(document.getElementById('g-regen').value);
    const id = name.toLowerCase().replace(/[^a-z0-9]/g, "_");

    if (gameData.generators.some(g => g.id === id)) {
        alert('Generator o tej nazwie już istnieje. Kliknij go w tabeli, aby edytować.');
        return;
    }

    gameData.generators.push({ id, name, maxEnergy, regen });
    newGeneratorForm();
    updateTables();
}

function saveGeneratorChanges() {
    if (!editingGeneratorId) return;

    const name = document.getElementById('g-name').value.trim();
    if (!name) {
        alert('Podaj nazwę generatora.');
        return;
    }

    const maxEnergy = parseFloat(document.getElementById('g-max-energy').value);
    const regen = parseFloat(document.getElementById('g-regen').value);
    const index = gameData.generators.findIndex(g => g.id === editingGeneratorId);

    if (index > -1) {
        gameData.generators[index] = { id: editingGeneratorId, name, maxEnergy, regen };
    }

    updateTables();
}

function addWeapon() {
    const generatorId = document.getElementById('w-generator-select').value;
    if (!generatorId) {
        alert('Wybierz generator przed dodaniem broni.');
        return;
    }

    const name = document.getElementById('w-name').value.trim();
    if (!name) {
        alert('Podaj nazwę broni.');
        return;
    }

    const dmg = parseFloat(document.getElementById('w-dmg').value);
    const cooldown = parseFloat(document.getElementById('w-cooldown').value);
    const cost = parseFloat(document.getElementById('w-cost').value);
    const id = name.toLowerCase().replace(/[^a-z0-9]/g, "_");
    const dps = dmg / cooldown;

    if (gameData.weapons.some(w => w.id === id)) {
        alert('Broń o tej nazwie już istnieje. Kliknij ją w tabeli, aby edytować.');
        return;
    }

    gameData.weapons.push({ id, name, generatorId, dmg, cooldown, cost, dps });
    newWeaponForm();
    updateTables();
}

function saveWeaponChanges() {
    if (!editingWeaponId) return;

    const generatorId = document.getElementById('w-generator-select').value;
    if (!generatorId) {
        alert('Wybierz generator przed zapisaniem broni.');
        return;
    }

    const name = document.getElementById('w-name').value.trim();
    if (!name) {
        alert('Podaj nazwę broni.');
        return;
    }

    const dmg = parseFloat(document.getElementById('w-dmg').value);
    const cooldown = parseFloat(document.getElementById('w-cooldown').value);
    const cost = parseFloat(document.getElementById('w-cost').value);
    const dps = dmg / cooldown;
    const index = gameData.weapons.findIndex(w => w.id === editingWeaponId);

    if (index > -1) {
        gameData.weapons[index] = { id: editingWeaponId, name, generatorId, dmg, cooldown, cost, dps };
    }

    updateTables();
}

function addEnemy() {
    const weaponAnchor = document.getElementById('e-weapon-select').value;
    if (!weaponAnchor) {
        alert('Wybierz broń kotwicę przed dodaniem wroga.');
        return;
    }

    const name = document.getElementById('e-name').value.trim();
    if (!name) {
        alert('Podaj nazwę wroga.');
        return;
    }

    const ttk = parseFloat(document.getElementById('e-ttk').value);
    const id = slugifyId(name);
    const stats = buildEnemyRecord(weaponAnchor, ttk);

    if (gameData.enemies.some(e => e.id === id)) {
        alert('Wróg o tej nazwie już istnieje. Kliknij go w tabeli, aby edytować.');
        return;
    }

    gameData.enemies.push({ id, name, ...stats });
    newEnemyForm();
    updateTables();
}

function saveEnemyChanges() {
    if (!editingEnemyId) return;

    const weaponAnchor = document.getElementById('e-weapon-select').value;
    if (!weaponAnchor) {
        alert('Wybierz broń kotwicę przed zapisaniem wroga.');
        return;
    }

    const name = document.getElementById('e-name').value.trim();
    if (!name) {
        alert('Podaj nazwę wroga.');
        return;
    }

    const ttk = parseFloat(document.getElementById('e-ttk').value);
    const stats = buildEnemyRecord(weaponAnchor, ttk);
    const index = gameData.enemies.findIndex(e => e.id === editingEnemyId);

    if (index > -1) {
        gameData.enemies[index] = { id: editingEnemyId, name, ...stats };
    }

    updateTables();
}

function populateSelect(selectId, items, valueKey, labelFn, currentValue) {
    const select = document.getElementById(selectId);
    select.innerHTML = '';
    items.forEach(item => {
        select.innerHTML += `<option value="${item[valueKey]}">${labelFn(item)}</option>`;
    });
    if (currentValue && items.some(i => i[valueKey] === currentValue)) {
        select.value = currentValue;
    } else if (items.length > 0) {
        select.value = items[0][valueKey];
    }
}

function updateTables() {
    const gTable = document.getElementById('generators-table');
    gTable.innerHTML = '';
    gameData.generators.forEach(g => {
        const rowClass = g.id === editingGeneratorId ? 'row-selected' : '';
        gTable.innerHTML += `<tr class="${rowClass}" data-id="${g.id}" onclick="loadGeneratorIntoForm('${g.id}')"><td><b>${g.name}</b></td><td><span class="badge badge-green">${g.maxEnergy}</span></td><td><span class="badge badge-blue">${g.regen}/s</span></td></tr>`;
    });

    const currentGenSelect = document.getElementById('w-generator-select').value;
    populateSelect('w-generator-select', gameData.generators, 'id', g => `${g.name} (${g.maxEnergy} E, ${g.regen} regen)`, currentGenSelect);

    const wTable = document.getElementById('weapons-table');
    wTable.innerHTML = '';
    const currentWeaponSelect = document.getElementById('e-weapon-select').value;

    gameData.weapons.forEach(w => {
        const gen = getGeneratorById(w.generatorId);
        const genName = gen ? gen.name : '—';
        const rowClass = w.id === editingWeaponId ? 'row-selected' : '';
        wTable.innerHTML += `<tr class="${rowClass}" data-id="${w.id}" onclick="loadWeaponIntoForm('${w.id}')"><td><b>${w.name}</b></td><td>${genName}</td><td>${w.dmg}</td><td>${w.cooldown}s</td><td><span class="badge badge-purple">${w.cost} E</span></td><td><span class="badge badge-blue">${w.dps.toFixed(0)}/s</span></td></tr>`;
    });

    populateSelect('e-weapon-select', gameData.weapons, 'id', w => `${w.name} (${w.dps.toFixed(0)} DPS)`);
    if (currentWeaponSelect && gameData.weapons.some(w => w.id === currentWeaponSelect)) {
        document.getElementById('e-weapon-select').value = currentWeaponSelect;
    }

    const eTable = document.getElementById('enemies-table');
    eTable.innerHTML = '';
    gameData.enemies.forEach(e => {
        const weapon = gameData.weapons.find(w => w.id === e.weaponAnchor);
        const weaponName = weapon ? weapon.name : "Brak";
        const rowClass = e.id === editingEnemyId ? 'row-selected' : '';
        const ttdLabel = e.instantKill || e.ttd <= 0 ? '1 strzał' : `${e.ttd}s`;
        eTable.innerHTML += `<tr class="${rowClass}" data-id="${e.id}" onclick="loadEnemyIntoForm('${e.id}')"><td><b>${e.name}</b></td><td>${weaponName}</td><td>${e.ttk}s</td><td><span class="badge badge-purple">${ttdLabel}</span></td><td><span class="badge badge-red">${e.hp} HP</span></td><td><span class="badge badge-orange">${(e.dps ?? 0).toFixed(1)}/s</span></td><td><span class="badge badge-purple">${(e.projectileDmg ?? 0).toFixed(1)}</span></td><td><span class="badge badge-red">${e.shotsToKill ?? '—'}</span></td><td><span class="badge badge-green">${e.shotsToKillAnchor ?? '—'}</span></td><td><span class="badge badge-orange">${e.threatPoints} pkt</span></td></tr>`;
    });

    if (pendingFormRestore?.weapon?.generatorId) {
        document.getElementById('w-generator-select').value = pendingFormRestore.weapon.generatorId;
    }
    if (pendingFormRestore?.enemy?.weaponAnchor) {
        document.getElementById('e-weapon-select').value = pendingFormRestore.enemy.weaponAnchor;
    }
    pendingFormRestore = null;

    highlightGeneratorRow();
    highlightWeaponRow();
    highlightEnemyRow();
    updateGeneratorFormMode();
    updateWeaponFormMode();
    updateEnemyFormMode();
    onWeaponGeneratorChange();
    calculateEnemyStats();
    document.getElementById('json-preview').value = JSON.stringify(gameData, null, 2);
    persistState();
}

window.onload = function() {
    const savedForm = loadState();
    if (savedForm && typeof savedForm === 'object') {
        pendingFormRestore = applyFormState(savedForm);
    }

    updateGeneratorSliders();
    updateTables();
    updateSliders();
    updateEnemySliders();
};
