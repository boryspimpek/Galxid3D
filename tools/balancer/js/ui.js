import {
    gameData, pendingFormRestore, editingGeneratorId, editingWeaponId,
    editingShipId, editingShieldId, clearPendingFormRestore
} from './state.js';
import { getGeneratorById, populateSelect } from './utils.js';
import { persistState } from './persistence.js';
import {
    highlightShipRow, updateShipFormMode,
    highlightShieldRow, updateShieldFormMode,
    getPlayerEffectiveHp
} from './player.js';
import { highlightGeneratorRow, updateGeneratorFormMode } from './generators.js';
import { highlightWeaponRow, updateWeaponFormMode, onWeaponGeneratorChange } from './weapons.js';
import { highlightEnemyRow, renderEnemiesTable } from './enemies.js';

function escapeHtml(text) {
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function buildRow(className, id, cells) {
    return `<tr class="${className}" data-id="${escapeHtml(id)}" data-table-row>${cells}</tr>`;
}

export function updateStatusBar() {
    const bar = document.getElementById('status-bar');
    if (!bar) return;
    const hp = getPlayerEffectiveHp();
    bar.innerHTML = `
        <span>Statki: <b>${gameData.ships.length}</b></span>
        <span>Tarcze: <b>${gameData.shields.length}</b></span>
        <span>Generatory: <b>${gameData.generators.length}</b></span>
        <span>Broń: <b>${gameData.weapons.length}</b></span>
        <span>Wrogowie: <b>${gameData.enemies.length}</b></span>
        <span>Efektywne HP (sandbox): <b>${hp}</b></span>
    `;
}

export function updateTables() {
    const shipsTable = document.getElementById('ships-table');
    shipsTable.innerHTML = '';
    gameData.ships.forEach(s => {
        const rowClass = s.id === editingShipId ? 'row-selected' : '';
        shipsTable.innerHTML += buildRow(rowClass, s.id,
            `<td><b>${escapeHtml(s.name)}</b></td><td><span class="badge badge-green">${s.armor}</span></td>`);
    });

    const shieldsTable = document.getElementById('shields-table');
    shieldsTable.innerHTML = '';
    gameData.shields.forEach(s => {
        const rowClass = s.id === editingShieldId ? 'row-selected' : '';
        shieldsTable.innerHTML += buildRow(rowClass, s.id,
            `<td><b>${escapeHtml(s.name)}</b></td><td><span class="badge badge-blue">${s.shield}</span></td>`);
    });

    const currentShipSelect = document.getElementById('e-ship-select').value;
    const currentShieldSelect = document.getElementById('e-shield-select').value;
    populateSelect('e-ship-select', gameData.ships, 'id', s => `${s.name} (${s.armor} armor)`, currentShipSelect);
    populateSelect('e-shield-select', gameData.shields, 'id', s => `${s.name} (${s.shield} shield)`, currentShieldSelect);

    const gTable = document.getElementById('generators-table');
    gTable.innerHTML = '';
    gameData.generators.forEach(g => {
        const rowClass = g.id === editingGeneratorId ? 'row-selected' : '';
        gTable.innerHTML += buildRow(rowClass, g.id,
            `<td><b>${escapeHtml(g.name)}</b></td><td><span class="badge badge-green">${g.maxEnergy}</span></td><td><span class="badge badge-blue">${g.regen}/s</span></td>`);
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
        wTable.innerHTML += buildRow(rowClass, w.id,
            `<td><b>${escapeHtml(w.name)}</b></td><td>${escapeHtml(genName)}</td><td>${w.dmg}</td><td>${w.cooldown}s</td><td><span class="badge badge-purple">${w.cost} E</span></td><td><span class="badge badge-blue">${w.dps.toFixed(0)}/s</span></td>`);
    });

    populateSelect('e-weapon-select', gameData.weapons, 'id', w => `${w.name} (${w.dps.toFixed(0)} DPS)`);
    if (currentWeaponSelect && gameData.weapons.some(w => w.id === currentWeaponSelect)) {
        document.getElementById('e-weapon-select').value = currentWeaponSelect;
    }

    renderEnemiesTable();

    if (pendingFormRestore?.weapon?.generatorId) {
        document.getElementById('w-generator-select').value = pendingFormRestore.weapon.generatorId;
    }
    if (pendingFormRestore?.enemy?.weaponAnchor) {
        document.getElementById('e-weapon-select').value = pendingFormRestore.enemy.weaponAnchor;
    }
    if (pendingFormRestore?.enemy?.shipId) {
        document.getElementById('e-ship-select').value = pendingFormRestore.enemy.shipId;
    }
    if (pendingFormRestore?.enemy?.shieldId) {
        document.getElementById('e-shield-select').value = pendingFormRestore.enemy.shieldId;
    }
    clearPendingFormRestore();

    highlightShipRow();
    highlightShieldRow();
    highlightGeneratorRow();
    highlightWeaponRow();
    highlightEnemyRow();
    updateShipFormMode();
    updateShieldFormMode();
    updateGeneratorFormMode();
    updateWeaponFormMode();
    onWeaponGeneratorChange();
    document.getElementById('json-preview').value = JSON.stringify(gameData, null, 2);
    updateStatusBar();
    persistState();
}
