import { gameData, editingEnemyId, setEditingEnemyId } from './state.js';
import { getEnemyById, shotsToKillWithWeapon } from './utils.js';
import { persistState } from './persistence.js';
import { updateTables } from './ui.js';
import { getPlayerEffectiveHp } from './player.js';

export function computeEnemyAttackStats() {
    const playerHp = getPlayerEffectiveHp();
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

export function computeEnemyDefenseStats(weaponAnchor, ttk, dps) {
    const anchorWeapon = gameData.weapons.find(w => w.id === weaponAnchor);
    if (!anchorWeapon) return { hp: 0, threatPoints: 0, shotsToKill: 0 };

    const hp = ttk <= 0 ? anchorWeapon.dmg : Math.round(anchorWeapon.dps * ttk);
    const threatPoints = Math.round(ttk * dps);
    const shotsToKill = shotsToKillWithWeapon(hp, anchorWeapon);
    return { hp, threatPoints, shotsToKill };
}

export function buildEnemyRecord(weaponAnchor, enemyTtk) {
    const attack = computeEnemyAttackStats();
    const defense = computeEnemyDefenseStats(weaponAnchor, enemyTtk, attack.dps);

    return {
        shipId: document.getElementById('e-ship-select').value,
        shieldId: document.getElementById('e-shield-select').value,
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

export function newEnemyForm() {
    setEditingEnemyId(null);
    document.getElementById('e-name').value = '';
    document.getElementById('e-ttd').value = 4;
    document.getElementById('e-attack-cd').value = 0.10;
    document.getElementById('e-ttk').value = 0.5;
    if (gameData.weapons.length > 0) {
        document.getElementById('e-weapon-select').value = gameData.weapons[0].id;
    }
    if (gameData.ships.length > 0) {
        document.getElementById('e-ship-select').value = gameData.ships[0].id;
    }
    if (gameData.shields.length > 0) {
        document.getElementById('e-shield-select').value = gameData.shields[0].id;
    }
    updateEnemySliders();
    highlightEnemyRow();
    updateEnemyFormMode();
    persistState();
}

export function updateEnemyFormMode() {
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

export function loadEnemyIntoForm(id) {
    const enemy = getEnemyById(id);
    if (!enemy) return;

    setEditingEnemyId(id);
    document.getElementById('e-name').value = enemy.name;
    document.getElementById('e-ttk').value = enemy.ttk;
    document.getElementById('e-ttd').value = enemy.ttd ?? 4;
    document.getElementById('e-attack-cd').value = enemy.attackCooldown ?? 0.5;

    const weaponSelect = document.getElementById('e-weapon-select');
    if (enemy.weaponAnchor && [...weaponSelect.options].some(o => o.value === enemy.weaponAnchor)) {
        weaponSelect.value = enemy.weaponAnchor;
    }

    const shipSelect = document.getElementById('e-ship-select');
    if (enemy.shipId && [...shipSelect.options].some(o => o.value === enemy.shipId)) {
        shipSelect.value = enemy.shipId;
    }

    const shieldSelect = document.getElementById('e-shield-select');
    if (enemy.shieldId && [...shieldSelect.options].some(o => o.value === enemy.shieldId)) {
        shieldSelect.value = enemy.shieldId;
    }

    updateEnemySliders();
    highlightEnemyRow();
    updateEnemyFormMode();
    persistState();
}

export function highlightEnemyRow() {
    document.querySelectorAll('#enemies-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingEnemyId);
    });
}

export function updateEnemySliders() {
    const attack = computeEnemyAttackStats();

    document.getElementById('stat-player-effective-hp').innerText = attack.playerHp;
    document.getElementById('lbl-ttd').innerText = attack.ttd <= 0 ? '0s (1 strzał)' : attack.ttd.toFixed(2) + 's';
    document.getElementById('lbl-attack-cd').innerText = attack.attackCooldown.toFixed(2) + 's';
    document.getElementById('lbl-ttk').innerText = parseFloat(document.getElementById('e-ttk').value).toFixed(2) + 's';
    document.getElementById('stat-enemy-dps').innerText = attack.instantKill ? '1 strzał' : attack.dps.toFixed(1) + ' DPS';
    document.getElementById('stat-projectile-dmg').innerText = attack.projectileDmg.toFixed(1) + ' DMG';
    document.getElementById('stat-shots-to-kill').innerText = attack.shotsToKill;

    calculateEnemyStats();
    persistState();
}

export function calculateEnemyStats() {
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

export function addEnemy() {
    const weaponAnchor = document.getElementById('e-weapon-select').value;
    const shipId = document.getElementById('e-ship-select').value;
    const shieldId = document.getElementById('e-shield-select').value;
    if (!weaponAnchor) {
        alert('Wybierz broń kotwicę przed dodaniem wroga.');
        return;
    }
    if (!shipId || !shieldId) {
        alert('Wybierz statek i tarczę gracza przed dodaniem wroga.');
        return;
    }
    if (getPlayerEffectiveHp() <= 0) {
        alert('Efektywne HP gracza musi być większe od zera (armor + tarcza).');
        return;
    }

    const name = document.getElementById('e-name').value.trim();
    if (!name) {
        alert('Podaj nazwę wroga.');
        return;
    }

    const ttk = parseFloat(document.getElementById('e-ttk').value);
    const id = name.toLowerCase().replace(/[^a-z0-9]/g, "_");
    const stats = buildEnemyRecord(weaponAnchor, ttk);

    if (gameData.enemies.some(e => e.id === id)) {
        alert('Wróg o tej nazwie już istnieje. Kliknij go w tabeli, aby edytować.');
        return;
    }

    gameData.enemies.push({ id, name, ...stats });
    newEnemyForm();
    updateTables();
}

export function saveEnemyChanges() {
    if (!editingEnemyId) return;

    const weaponAnchor = document.getElementById('e-weapon-select').value;
    const shipId = document.getElementById('e-ship-select').value;
    const shieldId = document.getElementById('e-shield-select').value;
    if (!weaponAnchor) {
        alert('Wybierz broń kotwicę przed zapisaniem wroga.');
        return;
    }
    if (!shipId || !shieldId) {
        alert('Wybierz statek i tarczę gracza przed zapisaniem wroga.');
        return;
    }
    if (getPlayerEffectiveHp() <= 0) {
        alert('Efektywne HP gracza musi być większe od zera (armor + tarcza).');
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
