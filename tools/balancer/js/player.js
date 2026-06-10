import { gameData, editingShipId, editingShieldId, setEditingShipId, setEditingShieldId } from './state.js';
import { slugifyId, getShipById, getShieldById, ensureEnemyIds } from './utils.js';
import { persistState } from './persistence.js';
import { updateTables } from './ui.js';
import { updateEnemySliders } from './enemies.js';

export function getPlayerEffectiveHp() {
    const ship = getShipById(document.getElementById('e-ship-select')?.value);
    const shield = getShieldById(document.getElementById('e-shield-select')?.value);
    return (ship?.armor ?? 0) + (shield?.shield ?? 0);
}

export function onPlayerLoadoutChange() {
    updateEnemySliders();
}

export function updateShipSliders() {
    document.getElementById('lbl-ship-armor').innerText = document.getElementById('ship-armor').value;
    if (document.getElementById('e-ship-select')?.options.length) {
        updateEnemySliders();
    } else {
        persistState();
    }
}

export function updateShieldSliders() {
    document.getElementById('lbl-shield-value').innerText = document.getElementById('shield-value').value;
    if (document.getElementById('e-shield-select')?.options.length) {
        updateEnemySliders();
    } else {
        persistState();
    }
}

export function newShipForm() {
    setEditingShipId(null);
    document.getElementById('ship-name').value = '';
    document.getElementById('ship-armor').value = 50;
    updateShipSliders();
    highlightShipRow();
    updateShipFormMode();
    persistState();
}

export function updateShipFormMode() {
    const isEditing = !!editingShipId;
    document.getElementById('btn-add-ship').hidden = isEditing;
    document.getElementById('btn-save-ship').hidden = !isEditing;
    const modeEl = document.getElementById('ship-form-mode');
    if (isEditing) {
        const ship = getShipById(editingShipId);
        modeEl.textContent = `Edycja: ${ship?.name ?? '—'}`;
        modeEl.className = 'form-mode form-mode-edit';
    } else {
        modeEl.textContent = 'Nowy statek';
        modeEl.className = 'form-mode form-mode-new';
    }
}

export function loadShipIntoForm(id) {
    const ship = getShipById(id);
    if (!ship) return;
    setEditingShipId(id);
    document.getElementById('ship-name').value = ship.name;
    document.getElementById('ship-armor').value = ship.armor;
    updateShipSliders();
    highlightShipRow();
    updateShipFormMode();
    persistState();
}

export function highlightShipRow() {
    document.querySelectorAll('#ships-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingShipId);
    });
}

export function addShip() {
    const name = document.getElementById('ship-name').value.trim();
    if (!name) {
        alert('Podaj nazwę statku.');
        return;
    }
    const armor = parseFloat(document.getElementById('ship-armor').value);
    const id = slugifyId(name);
    if (gameData.ships.some(s => s.id === id)) {
        alert('Statek o tej nazwie już istnieje. Kliknij go w tabeli, aby edytować.');
        return;
    }
    gameData.ships.push({ id, name, armor });
    newShipForm();
    updateTables();
}

export function saveShipChanges() {
    if (!editingShipId) return;
    const name = document.getElementById('ship-name').value.trim();
    if (!name) {
        alert('Podaj nazwę statku.');
        return;
    }
    const armor = parseFloat(document.getElementById('ship-armor').value);
    const index = gameData.ships.findIndex(s => s.id === editingShipId);
    if (index > -1) {
        gameData.ships[index] = { id: editingShipId, name, armor };
    }
    ensureEnemyIds();
    updateTables();
}

export function newShieldForm() {
    setEditingShieldId(null);
    document.getElementById('shield-name').value = '';
    document.getElementById('shield-value').value = 50;
    updateShieldSliders();
    highlightShieldRow();
    updateShieldFormMode();
    persistState();
}

export function updateShieldFormMode() {
    const isEditing = !!editingShieldId;
    document.getElementById('btn-add-shield').hidden = isEditing;
    document.getElementById('btn-save-shield').hidden = !isEditing;
    const modeEl = document.getElementById('shield-form-mode');
    if (isEditing) {
        const shield = getShieldById(editingShieldId);
        modeEl.textContent = `Edycja: ${shield?.name ?? '—'}`;
        modeEl.className = 'form-mode form-mode-edit';
    } else {
        modeEl.textContent = 'Nowa tarcza';
        modeEl.className = 'form-mode form-mode-new';
    }
}

export function loadShieldIntoForm(id) {
    const shield = getShieldById(id);
    if (!shield) return;
    setEditingShieldId(id);
    document.getElementById('shield-name').value = shield.name;
    document.getElementById('shield-value').value = shield.shield;
    updateShieldSliders();
    highlightShieldRow();
    updateShieldFormMode();
    persistState();
}

export function highlightShieldRow() {
    document.querySelectorAll('#shields-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingShieldId);
    });
}

export function addShield() {
    const name = document.getElementById('shield-name').value.trim();
    if (!name) {
        alert('Podaj nazwę tarczy.');
        return;
    }
    const shield = parseFloat(document.getElementById('shield-value').value);
    const id = slugifyId(name);
    if (gameData.shields.some(s => s.id === id)) {
        alert('Tarcza o tej nazwie już istnieje. Kliknij ją w tabeli, aby edytować.');
        return;
    }
    gameData.shields.push({ id, name, shield });
    newShieldForm();
    updateTables();
}

export function saveShieldChanges() {
    if (!editingShieldId) return;
    const name = document.getElementById('shield-name').value.trim();
    if (!name) {
        alert('Podaj nazwę tarczy.');
        return;
    }
    const shield = parseFloat(document.getElementById('shield-value').value);
    const index = gameData.shields.findIndex(s => s.id === editingShieldId);
    if (index > -1) {
        gameData.shields[index] = { id: editingShieldId, name, shield };
    }
    ensureEnemyIds();
    updateTables();
}
