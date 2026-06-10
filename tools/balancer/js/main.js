import { setPendingFormRestore } from './state.js';
import { loadState, applyFormState, importFromJson, downloadJson, resetAllData } from './persistence.js';
import { initTabs } from './tabs.js';
import { updateTables } from './ui.js';
import {
    updateShipSliders, updateShieldSliders, newShipForm, addShip, saveShipChanges,
    loadShipIntoForm, newShieldForm, addShield, saveShieldChanges,
    loadShieldIntoForm
} from './player.js';
import {
    updateGeneratorSliders, newGeneratorForm, addGenerator, saveGeneratorChanges,
    loadGeneratorIntoForm
} from './generators.js';
import {
    updateSliders, newWeaponForm, addWeapon, saveWeaponChanges, loadWeaponIntoForm,
    onWeaponGeneratorChange, startEnergySimulation
} from './weapons.js';
import {
    addNewEnemy, onEnemyPanelLoadoutChange, syncPanelFromEnemy,
    updateEnemyPanelInfo, handleEnemyTableInteraction, handleEnemyTableChange
} from './enemies.js';
import { editingEnemyId } from './state.js';

const TABLE_LOADERS = {
    'ships-table': loadShipIntoForm,
    'shields-table': loadShieldIntoForm,
    'generators-table': loadGeneratorIntoForm,
    'weapons-table': loadWeaponIntoForm
};

function bindEvents() {
    document.getElementById('ship-armor').addEventListener('input', updateShipSliders);
    document.getElementById('shield-value').addEventListener('input', updateShieldSliders);
    document.getElementById('g-max-energy').addEventListener('input', updateGeneratorSliders);
    document.getElementById('g-regen').addEventListener('input', updateGeneratorSliders);
    document.getElementById('w-dmg').addEventListener('input', updateSliders);
    document.getElementById('w-cooldown').addEventListener('input', updateSliders);
    document.getElementById('w-cost').addEventListener('input', updateSliders);
    document.getElementById('w-generator-select').addEventListener('change', onWeaponGeneratorChange);
    document.getElementById('e-ship-select').addEventListener('change', onEnemyPanelLoadoutChange);
    document.getElementById('e-shield-select').addEventListener('change', onEnemyPanelLoadoutChange);
    document.getElementById('e-weapon-select').addEventListener('change', onEnemyPanelLoadoutChange);

    document.getElementById('btn-new-ship').addEventListener('click', newShipForm);
    document.getElementById('btn-add-ship').addEventListener('click', addShip);
    document.getElementById('btn-save-ship').addEventListener('click', saveShipChanges);
    document.getElementById('btn-new-shield').addEventListener('click', newShieldForm);
    document.getElementById('btn-add-shield').addEventListener('click', addShield);
    document.getElementById('btn-save-shield').addEventListener('click', saveShieldChanges);
    document.getElementById('btn-new-generator').addEventListener('click', newGeneratorForm);
    document.getElementById('btn-add-generator').addEventListener('click', addGenerator);
    document.getElementById('btn-save-generator').addEventListener('click', saveGeneratorChanges);
    document.getElementById('btn-new-weapon').addEventListener('click', newWeaponForm);
    document.getElementById('btn-add-weapon').addEventListener('click', addWeapon);
    document.getElementById('btn-save-weapon').addEventListener('click', saveWeaponChanges);
    document.getElementById('btn-new-enemy').addEventListener('click', addNewEnemy);
    document.getElementById('btn-import-json').addEventListener('click', importFromJson);
    document.getElementById('btn-download-json').addEventListener('click', downloadJson);
    document.getElementById('btn-reset-data').addEventListener('click', resetAllData);

    const enemiesTable = document.getElementById('enemies-table');
    enemiesTable.addEventListener('click', handleEnemyTableInteraction);
    enemiesTable.addEventListener('input', handleEnemyTableChange);
    enemiesTable.addEventListener('change', handleEnemyTableChange);
    enemiesTable.addEventListener('blur', handleEnemyTableChange, true);

    document.body.addEventListener('click', (e) => {
        const row = e.target.closest('tr[data-table-row]');
        if (!row) return;
        const table = row.closest('tbody');
        if (!table) return;
        const loader = TABLE_LOADERS[table.id];
        if (loader) loader(row.dataset.id);
    });
}

function init() {
    initTabs();
    bindEvents();
    startEnergySimulation();

    const savedForm = loadState();
    if (savedForm && typeof savedForm === 'object') {
        setPendingFormRestore(applyFormState(savedForm));
    }

    updateGeneratorSliders();
    updateTables();
    if (editingEnemyId) {
        syncPanelFromEnemy(editingEnemyId);
    } else {
        updateEnemyPanelInfo();
    }
    updateShipSliders();
    updateShieldSliders();
    updateSliders();
}

document.addEventListener('DOMContentLoaded', init);
