import { gameData, editingGeneratorId, setEditingGeneratorId } from './state.js';
import { getGeneratorById } from './utils.js';
import { persistState } from './persistence.js';
import { updateTables } from './ui.js';

export function updateGeneratorSliders() {
    document.getElementById('lbl-g-max').innerText = document.getElementById('g-max-energy').value;
    document.getElementById('lbl-g-regen').innerText = document.getElementById('g-regen').value;
    persistState();
}

export function newGeneratorForm() {
    setEditingGeneratorId(null);
    document.getElementById('g-name').value = '';
    document.getElementById('g-max-energy').value = 300;
    document.getElementById('g-regen').value = 30;
    updateGeneratorSliders();
    highlightGeneratorRow();
    updateGeneratorFormMode();
    persistState();
}

export function updateGeneratorFormMode() {
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

export function loadGeneratorIntoForm(id) {
    const gen = getGeneratorById(id);
    if (!gen) return;

    setEditingGeneratorId(id);
    document.getElementById('g-name').value = gen.name;
    document.getElementById('g-max-energy').value = gen.maxEnergy;
    document.getElementById('g-regen').value = gen.regen;
    updateGeneratorSliders();
    highlightGeneratorRow();
    updateGeneratorFormMode();
    persistState();
}

export function highlightGeneratorRow() {
    document.querySelectorAll('#generators-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingGeneratorId);
    });
}

export function addGenerator() {
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

export function saveGeneratorChanges() {
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
