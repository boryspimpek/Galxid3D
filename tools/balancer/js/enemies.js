import { gameData, editingEnemyId, setEditingEnemyId } from './state.js';
import { slugifyId, getEnemyById, getShipById, getShieldById, shotsToKillWithWeapon } from './utils.js';
import { persistState } from './persistence.js';

const COEFF_FIELDS = {
    ttk: { step: 0.1, min: 0, max: 10 },
    ttd: { step: 0.1, min: 0, max: 60 },
    attackCooldown: { step: 0.05, min: 0.05, max: 3 }
};

function escapeHtml(text) {
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function buildNumSpinner(field, value, config) {
    const v = value ?? config.min;
    return `<div class="num-spinner" data-field="${field}">
        <button type="button" class="spinner-btn" data-step="-1" aria-label="Zmniejsz">▼</button>
        <input type="number" class="spinner-input" value="${v}" step="${config.step}" min="${config.min}" max="${config.max}">
        <button type="button" class="spinner-btn" data-step="1" aria-label="Zwiększ">▲</button>
    </div>`;
}

function formatEnemyCalculated(enemy) {
    const dpsLabel = enemy.instantKill ? '1 strzał' : `${(enemy.dps ?? 0).toFixed(1)}`;
    return {
        hp: `<span class="badge badge-red">${enemy.hp}</span>`,
        dps: `<span class="badge badge-orange">${dpsLabel}</span>`,
        projectileDmg: `<span class="badge badge-purple">${(enemy.projectileDmg ?? 0).toFixed(1)}</span>`,
        shotsToKill: `<span class="badge badge-red">${enemy.shotsToKill ?? '—'}</span>`,
        shotsToKillAnchor: `<span class="badge badge-green">${enemy.shotsToKillAnchor ?? '—'}</span>`,
        threatPoints: `<span class="badge badge-orange">${enemy.threatPoints} pkt</span>`
    };
}

function buildEnemyRow(enemy) {
    const weapon = gameData.weapons.find(w => w.id === enemy.weaponAnchor);
    const weaponName = weapon ? weapon.name : 'Brak';
    const rowClass = enemy.id === editingEnemyId ? 'row-selected' : '';
    const calc = formatEnemyCalculated(enemy);

    return `<tr class="${rowClass}" data-id="${escapeHtml(enemy.id)}" data-enemy-row>
        <td><input type="text" class="enemy-name-input" value="${escapeHtml(enemy.name)}"></td>
        <td class="enemy-weapon-cell">${escapeHtml(weaponName)}</td>
        <td>${buildNumSpinner('ttk', enemy.ttk, COEFF_FIELDS.ttk)}</td>
        <td>${buildNumSpinner('ttd', enemy.ttd, COEFF_FIELDS.ttd)}</td>
        <td>${buildNumSpinner('attackCooldown', enemy.attackCooldown, COEFF_FIELDS.attackCooldown)}</td>
        <td data-calc="hp">${calc.hp}</td>
        <td data-calc="dps">${calc.dps}</td>
        <td data-calc="projectileDmg">${calc.projectileDmg}</td>
        <td data-calc="shotsToKill">${calc.shotsToKill}</td>
        <td data-calc="shotsToKillAnchor">${calc.shotsToKillAnchor}</td>
        <td data-calc="threatPoints">${calc.threatPoints}</td>
    </tr>`;
}

export function updateEnemyRowCalculated(enemy) {
    const row = document.querySelector(`#enemies-table tr[data-id="${enemy.id}"]`);
    if (!row) return;

    const weapon = gameData.weapons.find(w => w.id === enemy.weaponAnchor);
    const weaponCell = row.querySelector('.enemy-weapon-cell');
    if (weaponCell) weaponCell.textContent = weapon ? weapon.name : 'Brak';

    const calc = formatEnemyCalculated(enemy);
    Object.entries(calc).forEach(([key, html]) => {
        const cell = row.querySelector(`[data-calc="${key}"]`);
        if (cell) cell.innerHTML = html;
    });
}

export function renderEnemiesTable() {
    recalcAllEnemies();
    const eTable = document.getElementById('enemies-table');
    eTable.innerHTML = gameData.enemies.map(buildEnemyRow).join('');
    highlightEnemyRow();
    updateEnemyPanelInfo();
}

export function getPlayerHpForEnemy(enemy) {
    const ship = getShipById(enemy.shipId);
    const shield = getShieldById(enemy.shieldId);
    return (ship?.armor ?? 0) + (shield?.shield ?? 0);
}

export function computeAttackStats(playerHp, ttd, attackCooldown) {
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

export function computeDefenseStats(weaponAnchor, ttk, dps) {
    const anchorWeapon = gameData.weapons.find(w => w.id === weaponAnchor);
    if (!anchorWeapon) return { hp: 0, threatPoints: 0, shotsToKillAnchor: 0 };

    const hp = ttk <= 0 ? anchorWeapon.dmg : Math.round(anchorWeapon.dps * ttk);
    const threatPoints = Math.round(ttk * dps);
    const shotsToKillAnchor = shotsToKillWithWeapon(hp, anchorWeapon);
    return { hp, threatPoints, shotsToKillAnchor };
}

export function recalcEnemy(enemy) {
    const attack = computeAttackStats(getPlayerHpForEnemy(enemy), enemy.ttd, enemy.attackCooldown);
    const defense = computeDefenseStats(enemy.weaponAnchor, enemy.ttk, attack.dps);

    enemy.playerHp = attack.playerHp;
    enemy.ttd = attack.ttd;
    enemy.dps = attack.dps;
    enemy.attackCooldown = attack.attackCooldown;
    enemy.projectileDmg = attack.projectileDmg;
    enemy.shotsToKill = attack.shotsToKill;
    enemy.instantKill = attack.instantKill;
    enemy.hp = defense.hp;
    enemy.threatPoints = defense.threatPoints;
    enemy.shotsToKillAnchor = defense.shotsToKillAnchor;

    return enemy;
}

export function recalcAllEnemies() {
    gameData.enemies.forEach(recalcEnemy);
}

function getPanelLoadout() {
    return {
        shipId: document.getElementById('e-ship-select')?.value ?? '',
        shieldId: document.getElementById('e-shield-select')?.value ?? '',
        weaponAnchor: document.getElementById('e-weapon-select')?.value ?? ''
    };
}

function validateLoadout(loadout) {
    if (!loadout.weaponAnchor) {
        alert('Wybierz broń kotwicę.');
        return false;
    }
    if (!loadout.shipId || !loadout.shieldId) {
        alert('Wybierz statek i tarczę gracza.');
        return false;
    }
    const ship = getShipById(loadout.shipId);
    const shield = getShieldById(loadout.shieldId);
    if ((ship?.armor ?? 0) + (shield?.shield ?? 0) <= 0) {
        alert('Efektywne HP gracza musi być większe od zera (armor + tarcza).');
        return false;
    }
    return true;
}

function uniqueEnemyId(baseName) {
    let id = slugifyId(baseName);
    if (!gameData.enemies.some(e => e.id === id)) return id;
    let suffix = 2;
    while (gameData.enemies.some(e => e.id === `${slugifyId(baseName)}_${suffix}`)) suffix++;
    return `${slugifyId(baseName)}_${suffix}`;
}

function uniqueEnemyName(base = 'Nowy wróg') {
    if (!gameData.enemies.some(e => e.name === base)) return base;
    let suffix = 2;
    while (gameData.enemies.some(e => e.name === `${base} ${suffix}`)) suffix++;
    return `${base} ${suffix}`;
}

export function syncPanelFromEnemy(id) {
    const enemy = getEnemyById(id);
    if (!enemy) return;

    const weaponSelect = document.getElementById('e-weapon-select');
    const shipSelect = document.getElementById('e-ship-select');
    const shieldSelect = document.getElementById('e-shield-select');

    if (enemy.weaponAnchor && [...weaponSelect.options].some(o => o.value === enemy.weaponAnchor)) {
        weaponSelect.value = enemy.weaponAnchor;
    }
    if (enemy.shipId && [...shipSelect.options].some(o => o.value === enemy.shipId)) {
        shipSelect.value = enemy.shipId;
    }
    if (enemy.shieldId && [...shieldSelect.options].some(o => o.value === enemy.shieldId)) {
        shieldSelect.value = enemy.shieldId;
    }
    updateEnemyPanelInfo();
}

export function updateEnemyPanelInfo() {
    const info = document.getElementById('enemy-panel-info');
    if (!info) return;

    const loadout = getPanelLoadout();
    const ship = getShipById(loadout.shipId);
    const shield = getShieldById(loadout.shieldId);
    const hp = (ship?.armor ?? 0) + (shield?.shield ?? 0);
    const weapon = gameData.weapons.find(w => w.id === loadout.weaponAnchor);
    const weaponLabel = weapon ? weapon.name : '—';

    info.innerHTML = `
        <span>Efektywne HP: <b>${hp}</b></span>
        <span>Broń kotwica: <b>${weaponLabel}</b></span>
        ${editingEnemyId ? '<span class="enemy-panel-selected">Edytujesz wybrany wiersz</span>' : '<span>Szablon dla nowego wroga</span>'}
    `;
}

export function selectEnemyRow(id) {
    setEditingEnemyId(id);
    syncPanelFromEnemy(id);
    highlightEnemyRow();
    updateEnemyPanelInfo();
    persistState();
}

export function highlightEnemyRow() {
    document.querySelectorAll('#enemies-table tr[data-enemy-row]').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingEnemyId);
    });
}

export function initEnemyPanel() {
    if (gameData.weapons.length > 0) {
        document.getElementById('e-weapon-select').value = gameData.weapons[0].id;
    }
    if (gameData.ships.length > 0) {
        document.getElementById('e-ship-select').value = gameData.ships[0].id;
    }
    if (gameData.shields.length > 0) {
        document.getElementById('e-shield-select').value = gameData.shields[0].id;
    }
    updateEnemyPanelInfo();
}

export function onEnemyPanelLoadoutChange() {
    if (!editingEnemyId) {
        updateEnemyPanelInfo();
        persistState();
        return;
    }

    const enemy = getEnemyById(editingEnemyId);
    if (!enemy) return;

    const loadout = getPanelLoadout();
    enemy.shipId = loadout.shipId;
    enemy.shieldId = loadout.shieldId;
    enemy.weaponAnchor = loadout.weaponAnchor;
    recalcEnemy(enemy);
    updateEnemyRowCalculated(enemy);
    highlightEnemyRow();
    updateEnemyPanelInfo();
    persistState();
}

export function addNewEnemy() {
    const loadout = getPanelLoadout();
    if (!validateLoadout(loadout)) return;

    const name = uniqueEnemyName();
    const enemy = {
        id: uniqueEnemyId(name),
        name,
        ...loadout,
        ttk: 0.5,
        ttd: 4,
        attackCooldown: 0.1
    };
    recalcEnemy(enemy);
    gameData.enemies.push(enemy);
    renderEnemiesTable();
    selectEnemyRow(enemy.id);
    persistState();
}

export function updateEnemyName(id, name) {
    const enemy = getEnemyById(id);
    if (!enemy) return;
    const trimmed = name.trim();
    if (!trimmed) return;
    enemy.name = trimmed;
    persistState();
}

export function updateEnemyCoeff(id, field, rawValue) {
    const enemy = getEnemyById(id);
    if (!enemy || !(field in COEFF_FIELDS)) return;

    const { min, max, step } = COEFF_FIELDS[field];
    let value = parseFloat(rawValue);
    if (Number.isNaN(value)) value = min;
    value = Math.round(value / step) * step;
    value = Math.max(min, Math.min(max, value));
    value = Math.round(value * 1000) / 1000;

    enemy[field] = value;
    recalcEnemy(enemy);
    updateEnemyRowCalculated(enemy);

    const row = document.querySelector(`#enemies-table tr[data-id="${id}"]`);
    const input = row?.querySelector(`[data-field="${field}"] .spinner-input`);
    if (input && parseFloat(input.value) !== value) {
        input.value = value;
    }

    persistState();
}

export function stepEnemyCoeff(id, field, direction) {
    const enemy = getEnemyById(id);
    if (!enemy || !(field in COEFF_FIELDS)) return;

    const { step } = COEFF_FIELDS[field];
    const current = enemy[field] ?? 0;
    updateEnemyCoeff(id, field, current + direction * step);
}

export function handleEnemyTableInteraction(event) {
    const spinnerBtn = event.target.closest('.spinner-btn');
    if (spinnerBtn) {
        event.stopPropagation();
        const wrapper = spinnerBtn.closest('[data-field]');
        const row = spinnerBtn.closest('tr[data-enemy-row]');
        if (!wrapper || !row) return;
        const step = parseFloat(spinnerBtn.dataset.step);
        stepEnemyCoeff(row.dataset.id, wrapper.dataset.field, step > 0 ? 1 : -1);
        return;
    }

    const input = event.target.closest('.spinner-input');
    if (input) {
        event.stopPropagation();
        return;
    }

    const nameInput = event.target.closest('.enemy-name-input');
    if (nameInput) {
        event.stopPropagation();
        return;
    }

    const row = event.target.closest('tr[data-enemy-row]');
    if (row) {
        selectEnemyRow(row.dataset.id);
    }
}

export function handleEnemyTableChange(event) {
    const input = event.target.closest('.spinner-input');
    if (input) {
        const wrapper = input.closest('[data-field]');
        const row = input.closest('tr[data-enemy-row]');
        if (wrapper && row) {
            updateEnemyCoeff(row.dataset.id, wrapper.dataset.field, input.value);
        }
        return;
    }

    const nameInput = event.target.closest('.enemy-name-input');
    if (nameInput) {
        const row = nameInput.closest('tr[data-enemy-row]');
        if (row) updateEnemyName(row.dataset.id, nameInput.value);
    }
}
