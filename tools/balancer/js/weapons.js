import { gameData } from './state.js';
import { slugifyId, getGeneratorById, getWeaponById, populateSelect, getExportGameData } from './utils.js';
import { persistState } from './persistence.js';
import { renderEnemiesTable } from './enemies.js';

const INPUT_FIELDS = {
    dmg: { step: 1, min: 1, max: 200, integer: true },
    cooldown: { step: 0.05, min: 0.05, max: 1.0 },
    cost: { step: 1, min: 1, max: 100, integer: true }
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

function buildGeneratorSelect(weapon) {
    if (gameData.generators.length === 0) {
        return '<select class="weapon-generator-select" disabled><option>Brak generatorów</option></select>';
    }
    const options = gameData.generators.map(g => {
        const selected = g.id === weapon.generatorId ? ' selected' : '';
        return `<option value="${escapeHtml(g.id)}"${selected}>${escapeHtml(g.name)}</option>`;
    }).join('');
    return `<select class="weapon-generator-select">${options}</select>`;
}

function formatWeaponDps(weapon) {
    if (!weapon.cooldown || weapon.cooldown <= 0) return '∞';
    return (weapon.dps ?? 0).toFixed(0);
}

export function recalcWeapon(weapon) {
    const dmg = Math.max(INPUT_FIELDS.dmg.min, weapon.dmg ?? INPUT_FIELDS.dmg.min);
    const cooldown = Math.max(INPUT_FIELDS.cooldown.min, weapon.cooldown ?? INPUT_FIELDS.cooldown.min);
    const cost = Math.max(INPUT_FIELDS.cost.min, weapon.cost ?? INPUT_FIELDS.cost.min);

    weapon.dmg = dmg;
    weapon.cooldown = cooldown;
    weapon.cost = cost;
    weapon.dps = cooldown > 0 ? dmg / cooldown : 0;

    return weapon;
}

function formatWeaponCalculated(weapon) {
    return {
        dps: `<span class="badge badge-blue">${formatWeaponDps(weapon)}/s</span>`
    };
}

function buildWeaponRow(weapon, index, total) {
    const calc = formatWeaponCalculated(weapon);
    const canMoveUp = index > 0;
    const canMoveDown = index < total - 1;

    return `<tr data-id="${escapeHtml(weapon.id)}" data-weapon-row>
        <td><input type="text" class="weapon-name-input" value="${escapeHtml(weapon.name)}"></td>
        <td>${buildGeneratorSelect(weapon)}</td>
        <td>${buildNumSpinner('dmg', weapon.dmg, INPUT_FIELDS.dmg)}</td>
        <td>${buildNumSpinner('cooldown', weapon.cooldown, INPUT_FIELDS.cooldown)}</td>
        <td>${buildNumSpinner('cost', weapon.cost, INPUT_FIELDS.cost)}</td>
        <td data-calc="dps">${calc.dps}</td>
        <td class="weapon-actions-cell">
            <div class="weapon-row-actions">
                <div class="weapon-reorder">
                    <button type="button" class="weapon-move-btn" data-dir="-1" aria-label="Przesuń wyżej" ${canMoveUp ? '' : 'disabled'}>▴</button>
                    <button type="button" class="weapon-move-btn" data-dir="1" aria-label="Przesuń niżej" ${canMoveDown ? '' : 'disabled'}>▾</button>
                </div>
                <button type="button" class="weapon-delete-btn" aria-label="Usuń broń">×</button>
            </div>
        </td>
    </tr>`;
}

export function updateWeaponRowCalculated(weapon) {
    const row = document.querySelector(`#weapons-table tr[data-id="${weapon.id}"]`);
    if (!row) return;

    const calc = formatWeaponCalculated(weapon);
    Object.entries(calc).forEach(([key, html]) => {
        const cell = row.querySelector(`[data-calc="${key}"]`);
        if (cell) cell.innerHTML = html;
    });
}

function refreshWeaponSelects() {
    const current = document.getElementById('e-weapon-select')?.value ?? '';
    populateSelect('e-weapon-select', gameData.weapons, 'id', w => `${w.name} (${w.dps.toFixed(0)} DPS)`, current);

    const preview = document.getElementById('json-preview');
    if (preview) {
        preview.value = JSON.stringify(getExportGameData(), null, 2);
    }
}

export function renderWeaponsTable() {
    gameData.weapons.forEach(recalcWeapon);
    const wTable = document.getElementById('weapons-table');
    const total = gameData.weapons.length;
    wTable.innerHTML = gameData.weapons.map((weapon, index) => buildWeaponRow(weapon, index, total)).join('');
    refreshWeaponSelects();
}

function uniqueWeaponId(baseName) {
    let id = slugifyId(baseName);
    if (!gameData.weapons.some(w => w.id === id)) return id;
    let suffix = 2;
    while (gameData.weapons.some(w => w.id === `${slugifyId(baseName)}_${suffix}`)) suffix++;
    return `${slugifyId(baseName)}_${suffix}`;
}

function uniqueWeaponName(base = 'Nowa broń') {
    if (!gameData.weapons.some(w => w.name === base)) return base;
    let suffix = 2;
    while (gameData.weapons.some(w => w.name === `${base} ${suffix}`)) suffix++;
    return `${base} ${suffix}`;
}

export function addNewWeapon() {
    if (gameData.generators.length === 0) {
        alert('Dodaj najpierw generator w sekcji Generatorów Energii.');
        return;
    }

    const name = uniqueWeaponName();
    const weapon = recalcWeapon({
        id: uniqueWeaponId(name),
        name,
        generatorId: gameData.generators[0].id,
        dmg: 10,
        cooldown: 0.2,
        cost: 10
    });

    gameData.weapons.push(weapon);
    renderWeaponsTable();
    renderEnemiesTable();
    persistState();
}

export function updateWeaponName(id, name) {
    const weapon = getWeaponById(id);
    if (!weapon) return;
    const trimmed = name.trim();
    if (!trimmed) return;
    weapon.name = trimmed;
    refreshWeaponSelects();
    persistState();
}

export function updateWeaponGenerator(id, generatorId) {
    const weapon = getWeaponById(id);
    if (!weapon || !getGeneratorById(generatorId)) return;
    weapon.generatorId = generatorId;
    persistState();
}

export function updateWeaponInput(id, field, rawValue) {
    const weapon = getWeaponById(id);
    if (!weapon || !(field in INPUT_FIELDS)) return;

    const { min, max, step, integer } = INPUT_FIELDS[field];
    let value = parseFloat(rawValue);
    if (Number.isNaN(value)) value = min;
    value = Math.round(value / step) * step;
    value = Math.max(min, Math.min(max, value));
    if (integer) value = Math.round(value);
    else value = Math.round(value * 1000) / 1000;

    weapon[field] = value;
    recalcWeapon(weapon);
    updateWeaponRowCalculated(weapon);
    refreshWeaponSelects();
    renderEnemiesTable();

    const row = document.querySelector(`#weapons-table tr[data-id="${id}"]`);
    const input = row?.querySelector(`[data-field="${field}"] .spinner-input`);
    if (input && parseFloat(input.value) !== value) {
        input.value = value;
    }

    persistState();
}

export function stepWeaponInput(id, field, direction) {
    const weapon = getWeaponById(id);
    if (!weapon || !(field in INPUT_FIELDS)) return;

    const { step } = INPUT_FIELDS[field];
    const current = weapon[field] ?? 0;
    updateWeaponInput(id, field, current + direction * step);
}

export function moveWeapon(id, direction) {
    const index = gameData.weapons.findIndex(w => w.id === id);
    if (index === -1) return;

    const newIndex = index + direction;
    if (newIndex < 0 || newIndex >= gameData.weapons.length) return;

    const [weapon] = gameData.weapons.splice(index, 1);
    gameData.weapons.splice(newIndex, 0, weapon);
    renderWeaponsTable();
    persistState();
}

export function deleteWeapon(id) {
    const index = gameData.weapons.findIndex(w => w.id === id);
    if (index === -1) return;

    gameData.weapons.splice(index, 1);
    renderWeaponsTable();
    renderEnemiesTable();
    persistState();
}

export function handleWeaponTableInteraction(event) {
    const moveBtn = event.target.closest('.weapon-move-btn');
    if (moveBtn) {
        event.stopPropagation();
        if (moveBtn.disabled) return;
        const row = moveBtn.closest('tr[data-weapon-row]');
        if (row) moveWeapon(row.dataset.id, parseInt(moveBtn.dataset.dir, 10));
        return;
    }

    const deleteBtn = event.target.closest('.weapon-delete-btn');
    if (deleteBtn) {
        event.stopPropagation();
        const row = deleteBtn.closest('tr[data-weapon-row]');
        if (row) deleteWeapon(row.dataset.id);
        return;
    }

    const spinnerBtn = event.target.closest('.spinner-btn');
    if (spinnerBtn) {
        event.stopPropagation();
        const wrapper = spinnerBtn.closest('[data-field]');
        const row = spinnerBtn.closest('tr[data-weapon-row]');
        if (!wrapper || !row) return;
        const step = parseFloat(spinnerBtn.dataset.step);
        stepWeaponInput(row.dataset.id, wrapper.dataset.field, step > 0 ? 1 : -1);
        return;
    }

    if (event.target.closest('.weapon-name-input, .weapon-generator-select, .spinner-input')) {
        event.stopPropagation();
    }
}

export function handleWeaponTableChange(event) {
    const select = event.target.closest('.weapon-generator-select');
    if (select) {
        const row = select.closest('tr[data-weapon-row]');
        if (row) updateWeaponGenerator(row.dataset.id, select.value);
        return;
    }

    const input = event.target.closest('.spinner-input');
    if (input) {
        const wrapper = input.closest('[data-field]');
        const row = input.closest('tr[data-weapon-row]');
        if (wrapper && row) {
            updateWeaponInput(row.dataset.id, wrapper.dataset.field, input.value);
        }
        return;
    }

    const nameInput = event.target.closest('.weapon-name-input');
    if (nameInput) {
        const row = nameInput.closest('tr[data-weapon-row]');
        if (row) updateWeaponName(row.dataset.id, nameInput.value);
    }
}
