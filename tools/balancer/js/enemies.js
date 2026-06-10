import { gameData, editingEnemyId, setEditingEnemyId } from './state.js';
import { slugifyId, getEnemyById, getShipById, getShieldById, shotsToKillWithWeapon } from './utils.js';
import { persistState } from './persistence.js';

const INPUT_FIELDS = {
    hp: { step: 1, min: 1, max: 5000, integer: true },
    projectileDmg: { step: 0.5, min: 0, max: 500 },
    attackCooldown: { step: 0.05, min: 0, max: 3 }
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
        <button type="button" class="spinner-btn" data-step="1" aria-label="Zwiększ">▴</button>
        <input type="number" class="spinner-input" value="${v}" step="${config.step}" min="${config.min}" max="${config.max}">
        <button type="button" class="spinner-btn" data-step="-1" aria-label="Zmniejsz">▾</button>
    </div>`;
}

function formatTtk(ttk) {
    if (ttk <= 0) return '<span class="badge badge-green">0</span>';
    return `<span class="badge badge-green">${ttk.toFixed(2)}</span>`;
}

function formatTtd(enemy) {
    if (enemy.projectileDmg <= 0) return '<span class="badge badge-red">—</span>';
    if (enemy.instantKill || enemy.ttd <= 0) return '<span class="badge badge-red">1 strzał</span>';
    return `<span class="badge badge-red">${enemy.ttd.toFixed(2)}</span>`;
}

function formatDps(enemy) {
    if (enemy.projectileDmg <= 0) return '0';
    if (enemy.attackCooldown <= 0) return '∞';
    if (enemy.instantKill) return '1 strzał';
    return (enemy.dps ?? 0).toFixed(1);
}

function formatShotsToKill(enemy) {
    if (enemy.projectileDmg <= 0) return '—';
    return enemy.shotsToKill ?? '—';
}

function formatEnemyCalculated(enemy) {
    return {
        dps: `<span class="badge badge-orange">${formatDps(enemy)}</span>`,
        shotsToKill: `<span class="badge badge-red">${formatShotsToKill(enemy)}</span>`,
        shotsToKillAnchor: `<span class="badge badge-green">${enemy.shotsToKillAnchor ?? '—'}</span>`,
        ttk: formatTtk(enemy.ttk ?? 0),
        ttd: formatTtd(enemy),
        threatPoints: `<span class="badge badge-orange">${enemy.threatPoints} pkt</span>`
    };
}

function buildEnemyRow(enemy, index, total) {
    const rowClass = enemy.id === editingEnemyId ? 'row-selected' : '';
    const calc = formatEnemyCalculated(enemy);
    const canMoveUp = index > 0;
    const canMoveDown = index < total - 1;

    return `<tr class="${rowClass}" data-id="${escapeHtml(enemy.id)}" data-enemy-row>
        <td><input type="text" class="enemy-name-input" value="${escapeHtml(enemy.name)}"></td>
        <td>${buildNumSpinner('hp', enemy.hp, INPUT_FIELDS.hp)}</td>
        <td>${buildNumSpinner('projectileDmg', enemy.projectileDmg, INPUT_FIELDS.projectileDmg)}</td>
        <td>${buildNumSpinner('attackCooldown', enemy.attackCooldown, INPUT_FIELDS.attackCooldown)}</td>
        <td data-calc="dps">${calc.dps}</td>
        <td data-calc="shotsToKillAnchor">${calc.shotsToKillAnchor}</td>
        <td data-calc="shotsToKill">${calc.shotsToKill}</td>
        <td data-calc="ttk">${calc.ttk}</td>
        <td data-calc="ttd">${calc.ttd}</td>
        <td data-calc="threatPoints">${calc.threatPoints}</td>
        <td class="enemy-actions-cell">
            <div class="enemy-row-actions">
                <div class="enemy-reorder">
                    <button type="button" class="enemy-move-btn" data-dir="-1" aria-label="Przesuń wyżej" ${canMoveUp ? '' : 'disabled'}>▴</button>
                    <button type="button" class="enemy-move-btn" data-dir="1" aria-label="Przesuń niżej" ${canMoveDown ? '' : 'disabled'}>▾</button>
                </div>
                <button type="button" class="enemy-delete-btn" aria-label="Usuń wroga">×</button>
            </div>
        </td>
    </tr>`;
}

export function updateEnemyRowCalculated(enemy) {
    const row = document.querySelector(`#enemies-table tr[data-id="${enemy.id}"]`);
    if (!row) return;

    const calc = formatEnemyCalculated(enemy);
    Object.entries(calc).forEach(([key, html]) => {
        const cell = row.querySelector(`[data-calc="${key}"]`);
        if (cell) cell.innerHTML = html;
    });
}

export function renderEnemiesTable() {
    recalcAllEnemies();
    const eTable = document.getElementById('enemies-table');
    const total = gameData.enemies.length;
    eTable.innerHTML = gameData.enemies.map((enemy, index) => buildEnemyRow(enemy, index, total)).join('');
    highlightEnemyRow();
    updateEnemyPanelInfo();
}

export function getPlayerHpForEnemy(enemy) {
    const ship = getShipById(enemy.shipId);
    const shield = getShieldById(enemy.shieldId);
    return (ship?.armor ?? 0) + (shield?.shield ?? 0);
}

export function getGlobalWeaponAnchor() {
    return document.getElementById('e-weapon-select')?.value ?? '';
}

export function recalcEnemy(enemy) {
    const anchorWeapon = gameData.weapons.find(w => w.id === getGlobalWeaponAnchor());
    const playerHp = getPlayerHpForEnemy(enemy);
    const hp = enemy.hp ?? 1;
    const projectileDmg = Math.max(0, enemy.projectileDmg ?? 0);
    const attackCooldown = Math.max(0, enemy.attackCooldown ?? 0);

    let dps = 0;
    let ttd = 0;
    let shotsToKill = 0;
    let instantKill = false;

    if (projectileDmg <= 0) {
        dps = 0;
        ttd = 0;
        shotsToKill = 0;
    } else if (attackCooldown <= 0) {
        dps = Infinity;
        shotsToKill = projectileDmg >= playerHp ? 1 : Math.ceil(playerHp / projectileDmg);
        instantKill = true;
        ttd = 0;
    } else {
        dps = projectileDmg / attackCooldown;
        if (projectileDmg >= playerHp) {
            instantKill = true;
            ttd = 0;
            shotsToKill = 1;
        } else {
            ttd = playerHp / dps;
            shotsToKill = Math.ceil(playerHp / projectileDmg);
        }
    }

    let ttk = 0;
    let shotsToKillAnchor = 0;
    if (anchorWeapon && hp > 0) {
        if (hp <= anchorWeapon.dmg) {
            ttk = 0;
            shotsToKillAnchor = 1;
        } else {
            ttk = hp / anchorWeapon.dps;
            shotsToKillAnchor = shotsToKillWithWeapon(hp, anchorWeapon);
        }
    }

    enemy.playerHp = playerHp;
    enemy.hp = hp;
    enemy.projectileDmg = projectileDmg;
    enemy.attackCooldown = attackCooldown;
    enemy.dps = Number.isFinite(dps) ? dps : 0;
    enemy.ttd = ttd;
    enemy.ttk = ttk;
    enemy.shotsToKill = shotsToKill;
    enemy.shotsToKillAnchor = shotsToKillAnchor;
    const threat = ttk * dps;
    enemy.threatPoints = Number.isFinite(threat) ? Math.round(threat) : 0;
    enemy.instantKill = instantKill;

    return enemy;
}

export function recalcAllEnemies() {
    gameData.enemies.forEach(recalcEnemy);
}

function getPanelLoadout() {
    return {
        shipId: document.getElementById('e-ship-select')?.value ?? '',
        shieldId: document.getElementById('e-shield-select')?.value ?? ''
    };
}

function validateLoadout(loadout) {
    if (!getGlobalWeaponAnchor()) {
        alert('Wybierz broń gracza do obliczeń.');
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

    const shipSelect = document.getElementById('e-ship-select');
    const shieldSelect = document.getElementById('e-shield-select');

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
    const weapon = gameData.weapons.find(w => w.id === getGlobalWeaponAnchor());
    const weaponLabel = weapon ? weapon.name : '—';

    info.innerHTML = `
        <span>Efektywne HP: <b>${hp}</b></span>
        <span>Broń gracza: <b>${weaponLabel}</b></span>
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

export function onGlobalWeaponChange() {
    if (!getGlobalWeaponAnchor()) {
        updateEnemyPanelInfo();
        persistState();
        return;
    }
    recalcAllEnemies();
    gameData.enemies.forEach(e => updateEnemyRowCalculated(e));
    updateEnemyPanelInfo();
    persistState();
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
    recalcEnemy(enemy);
    updateEnemyRowCalculated(enemy);
    highlightEnemyRow();
    updateEnemyPanelInfo();
    persistState();
}

export function moveEnemy(id, direction) {
    const index = gameData.enemies.findIndex(e => e.id === id);
    if (index === -1) return;

    const newIndex = index + direction;
    if (newIndex < 0 || newIndex >= gameData.enemies.length) return;

    const [enemy] = gameData.enemies.splice(index, 1);
    gameData.enemies.splice(newIndex, 0, enemy);
    renderEnemiesTable();
    selectEnemyRow(id);
    persistState();
}

export function deleteEnemy(id) {
    const index = gameData.enemies.findIndex(e => e.id === id);
    if (index === -1) return;

    gameData.enemies.splice(index, 1);
    if (editingEnemyId === id) {
        setEditingEnemyId(null);
        updateEnemyPanelInfo();
    }
    renderEnemiesTable();
    persistState();
}

export function addNewEnemy() {
    const loadout = getPanelLoadout();
    if (!validateLoadout(loadout)) return;

    const name = uniqueEnemyName();
    const enemy = {
        id: uniqueEnemyId(name),
        name,
        shipId: loadout.shipId,
        shieldId: loadout.shieldId,
        hp: 25,
        projectileDmg: 2.5,
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

export function updateEnemyInput(id, field, rawValue) {
    const enemy = getEnemyById(id);
    if (!enemy || !(field in INPUT_FIELDS)) return;

    const { min, max, step, integer } = INPUT_FIELDS[field];
    let value = parseFloat(rawValue);
    if (Number.isNaN(value)) value = min;
    value = Math.round(value / step) * step;
    value = Math.max(min, Math.min(max, value));
    if (integer) value = Math.round(value);
    else value = Math.round(value * 1000) / 1000;

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

export function stepEnemyInput(id, field, direction) {
    const enemy = getEnemyById(id);
    if (!enemy || !(field in INPUT_FIELDS)) return;

    const { step } = INPUT_FIELDS[field];
    const current = enemy[field] ?? 0;
    updateEnemyInput(id, field, current + direction * step);
}

export function handleEnemyTableInteraction(event) {
    const moveBtn = event.target.closest('.enemy-move-btn');
    if (moveBtn) {
        event.stopPropagation();
        if (moveBtn.disabled) return;
        const row = moveBtn.closest('tr[data-enemy-row]');
        if (row) moveEnemy(row.dataset.id, parseInt(moveBtn.dataset.dir, 10));
        return;
    }

    const deleteBtn = event.target.closest('.enemy-delete-btn');
    if (deleteBtn) {
        event.stopPropagation();
        const row = deleteBtn.closest('tr[data-enemy-row]');
        if (row) deleteEnemy(row.dataset.id);
        return;
    }

    const spinnerBtn = event.target.closest('.spinner-btn');
    if (spinnerBtn) {
        event.stopPropagation();
        const wrapper = spinnerBtn.closest('[data-field]');
        const row = spinnerBtn.closest('tr[data-enemy-row]');
        if (!wrapper || !row) return;
        const step = parseFloat(spinnerBtn.dataset.step);
        stepEnemyInput(row.dataset.id, wrapper.dataset.field, step > 0 ? 1 : -1);
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
            updateEnemyInput(row.dataset.id, wrapper.dataset.field, input.value);
        }
        return;
    }

    const nameInput = event.target.closest('.enemy-name-input');
    if (nameInput) {
        const row = nameInput.closest('tr[data-enemy-row]');
        if (row) updateEnemyName(row.dataset.id, nameInput.value);
    }
}
