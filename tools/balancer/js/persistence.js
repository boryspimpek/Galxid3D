import {
    STORAGE_KEY, gameData, editingGeneratorId, editingWeaponId, editingEnemyId,
    editingShipId, editingShieldId, setGameData, resetEditingIds, getDefaultGameData,
    setEditingGeneratorId, setEditingWeaponId, setEditingEnemyId,
    setEditingShipId, setEditingShieldId
} from './state.js';
import { ensureGameDataArrays, getExportGameData, isValidGameData } from './utils.js';
import { updateTables } from './ui.js';
import { newShipForm, newShieldForm } from './player.js';
import { newGeneratorForm } from './generators.js';
import { newWeaponForm } from './weapons.js';
import { initEnemyPanel } from './enemies.js';

export function collectFormState() {
    return {
        editingGeneratorId,
        editingWeaponId,
        editingEnemyId,
        editingShipId,
        editingShieldId,
        ship: {
            name: document.getElementById('ship-name').value,
            armor: parseFloat(document.getElementById('ship-armor').value)
        },
        shield: {
            name: document.getElementById('shield-name').value,
            shield: parseFloat(document.getElementById('shield-value').value)
        },
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
            playerWeaponId: document.getElementById('e-weapon-select').value,
            shipId: document.getElementById('e-ship-select').value,
            shieldId: document.getElementById('e-shield-select').value
        }
    };
}

export function applyFormState(form) {
    if (!form) return null;

    setEditingGeneratorId(form.editingGeneratorId ?? null);
    setEditingWeaponId(form.editingWeaponId ?? null);
    setEditingEnemyId(form.editingEnemyId ?? null);
    setEditingShipId(form.editingShipId ?? null);
    setEditingShieldId(form.editingShieldId ?? null);

    if (form.ship) {
        document.getElementById('ship-name').value = form.ship.name ?? '';
        document.getElementById('ship-armor').value = form.ship.armor ?? 50;
    }
    if (form.shield) {
        document.getElementById('shield-name').value = form.shield.name ?? '';
        document.getElementById('shield-value').value = form.shield.shield ?? 50;
    }
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
    return form;
}

export function persistState() {
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify({
            gameData,
            form: collectFormState()
        }));
    } catch (e) {
        console.warn('Nie udało się zapisać ustawień:', e);
    }
}

export function loadState() {
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (!raw) return false;

        const saved = JSON.parse(raw);
        if (isValidGameData(saved.gameData)) {
            setGameData(saved.gameData);
            ensureGameDataArrays();
            return saved.form ?? true;
        }
        if (isValidGameData(saved)) {
            setGameData(saved);
            ensureGameDataArrays();
            return true;
        }
    } catch (e) {
        console.warn('Nie udało się wczytać ustawień:', e);
    }
    return false;
}

export function importFromJson() {
    try {
        const parsed = JSON.parse(document.getElementById('json-preview').value);
        const data = isValidGameData(parsed) ? parsed : parsed.gameData;

        if (!isValidGameData(data)) {
            alert('Nieprawidłowy JSON. Oczekiwane pola: generators, weapons, enemies.');
            return;
        }

        setGameData(data);
        ensureGameDataArrays();
        resetEditingIds();
        updateTables();
        persistState();
    } catch (e) {
        alert('Błąd parsowania JSON: ' + e.message);
    }
}

export function downloadJson() {
    const blob = new Blob([JSON.stringify(getExportGameData(), null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'balancer_export.json';
    link.click();
    URL.revokeObjectURL(url);
}

export function resetAllData() {
    if (!confirm('Przywrócić domyślne dane i wyczyścić zapis w przeglądarce?')) return;

    localStorage.removeItem(STORAGE_KEY);
    setGameData(getDefaultGameData());
    newShipForm();
    newShieldForm();
    newGeneratorForm();
    newWeaponForm();
    resetEditingIds();
    initEnemyPanel();
    updateTables();
}
