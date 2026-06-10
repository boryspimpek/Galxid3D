import { gameData, getDefaultGameData } from './state.js';

export function slugifyId(name) {
    return name.toLowerCase().replace(/[^a-z0-9]/g, "_");
}

export function isValidGameData(data) {
    return data
        && Array.isArray(data.generators)
        && Array.isArray(data.weapons)
        && Array.isArray(data.enemies);
}

export function getGeneratorById(id) {
    return gameData.generators.find(g => g.id === id);
}

export function getWeaponById(id) {
    return gameData.weapons.find(w => w.id === id);
}

export function getEnemyById(id) {
    return gameData.enemies.find(e => e.id === id);
}

export function getShipById(id) {
    return gameData.ships.find(s => s.id === id);
}

export function getShieldById(id) {
    return gameData.shields.find(s => s.id === id);
}

export function populateSelect(selectId, items, valueKey, labelFn, currentValue) {
    const select = document.getElementById(selectId);
    if (!select) return;
    select.innerHTML = '';
    items.forEach(item => {
        select.innerHTML += `<option value="${item[valueKey]}">${labelFn(item)}</option>`;
    });
    if (currentValue && items.some(i => i[valueKey] === currentValue)) {
        select.value = currentValue;
    } else if (items.length > 0) {
        select.value = items[0][valueKey];
    }
}

export function shotsToKillWithWeapon(hp, weapon) {
    if (!weapon || hp <= 0) return 0;
    return hp <= weapon.dmg ? 1 : Math.ceil(hp / weapon.dmg);
}

export function ensureEnemyIds() {
    gameData.enemies.forEach(enemy => {
        if (!enemy.id) {
            let id = slugifyId(enemy.name);
            let suffix = 2;
            while (gameData.enemies.some(other => other !== enemy && other.id === id)) {
                id = `${slugifyId(enemy.name)}_${suffix++}`;
            }
            enemy.id = id;
        }

        if (enemy.shipId == null && gameData.ships.length > 0) {
            enemy.shipId = gameData.ships[0].id;
        }
        if (enemy.shieldId == null && gameData.shields.length > 0) {
            enemy.shieldId = gameData.shields[0].id;
        }

        if (enemy.hp == null) enemy.hp = 25;
        if (enemy.projectileDmg == null) enemy.projectileDmg = 10;
        if (enemy.attackCooldown == null) enemy.attackCooldown = 0.5;

        delete enemy.weaponAnchor;
    });
}

export function getExportGameData() {
    return {
        ...gameData,
        enemies: gameData.enemies.map(({ weaponAnchor, ...enemy }) => enemy)
    };
}

export function ensureGameDataArrays() {
    const defaults = getDefaultGameData();
    if (!Array.isArray(gameData.ships)) gameData.ships = defaults.ships;
    if (!Array.isArray(gameData.shields)) gameData.shields = defaults.shields;
    ensureEnemyIds();
}
