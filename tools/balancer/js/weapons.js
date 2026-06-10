import { gameData, currentSimEnergy, editingWeaponId, setEditingWeaponId, setCurrentSimEnergy } from './state.js';
import { getGeneratorById, getWeaponById } from './utils.js';
import { persistState } from './persistence.js';
import { updateTables } from './ui.js';
import { calculateEnemyStats } from './enemies.js';

export function getSelectedWeaponGenerator() {
    const id = document.getElementById('w-generator-select').value;
    return getGeneratorById(id);
}

export function resetSimEnergy() {
    const gen = getSelectedWeaponGenerator();
    setCurrentSimEnergy(gen ? gen.maxEnergy : 0);
}

export function startEnergySimulation() {
    setInterval(() => {
        const gen = getSelectedWeaponGenerator();
        if (!gen) return;

        const cooldown = parseFloat(document.getElementById('w-cooldown').value);
        const cost = parseFloat(document.getElementById('w-cost').value);
        const maxEnergy = gen.maxEnergy;
        const regen = gen.regen;

        let energy = currentSimEnergy + regen * 0.1;
        const drainPerSecond = cost / cooldown;
        energy -= drainPerSecond * 0.1;

        if (energy > maxEnergy) energy = maxEnergy;
        if (energy < 0) energy = 0;
        setCurrentSimEnergy(energy);

        const bar = document.getElementById('energy-bar');
        const pct = maxEnergy > 0 ? (energy / maxEnergy) * 100 : 0;
        bar.style.width = pct + '%';
        document.getElementById('energy-text').innerText = `⚡ ENERGIA GENERATORA: ${Math.round(energy)} / ${maxEnergy}`;
    }, 100);
}

export function onWeaponGeneratorChange() {
    const gen = getSelectedWeaponGenerator();
    const info = document.getElementById('w-generator-info');
    if (gen) {
        info.innerText = `${gen.maxEnergy} max E · ${gen.regen} regen/s`;
    } else {
        info.innerText = 'Brak generatora — dodaj go w zakładce Uzbrojenie';
    }
    resetSimEnergy();
    sim();
}

export function sim() {
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

export function updateSliders() {
    document.getElementById('lbl-dmg').innerText = document.getElementById('w-dmg').value;
    document.getElementById('lbl-cd').innerText = parseFloat(document.getElementById('w-cooldown').value).toFixed(2) + 's';
    document.getElementById('lbl-cost').innerText = document.getElementById('w-cost').value;
    sim();
    calculateEnemyStats();
    persistState();
}

export function newWeaponForm() {
    setEditingWeaponId(null);
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

export function updateWeaponFormMode() {
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

export function loadWeaponIntoForm(id) {
    const weapon = getWeaponById(id);
    if (!weapon) return;

    setEditingWeaponId(id);
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

export function highlightWeaponRow() {
    document.querySelectorAll('#weapons-table tr').forEach(row => {
        row.classList.toggle('row-selected', row.dataset.id === editingWeaponId);
    });
}

export function addWeapon() {
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

export function saveWeaponChanges() {
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
