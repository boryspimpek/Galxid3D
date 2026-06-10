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

        const ship = gameData.ships.find(s => s.id === enemy.shipId);
        const shield = gameData.shields.find(s => s.id === enemy.shieldId);
        enemy.playerHp = (ship?.armor ?? 0) + (shield?.shield ?? 0);

        if (enemy.ttd == null) enemy.ttd = enemy.dps > 0 && enemy.playerHp > 0 ? enemy.playerHp / enemy.dps : 4;
        if (enemy.attackCooldown == null) {
            enemy.attackCooldown = enemy.projectileDmg && enemy.dps > 0
                ? enemy.projectileDmg / enemy.dps
                : 0.5;
        }
        if (enemy.ttd <= 0) {
            enemy.dps = 0;
            enemy.projectileDmg = enemy.playerHp;
            enemy.shotsToKill = 1;
            enemy.instantKill = true;
        } else {
            enemy.dps = enemy.playerHp / enemy.ttd;
            enemy.projectileDmg = enemy.dps * enemy.attackCooldown;
            enemy.shotsToKill = enemy.projectileDmg > 0
                ? Math.ceil(enemy.playerHp / enemy.projectileDmg)
                : 0;
            enemy.instantKill = false;
        }

        if (enemy.shotsToKillAnchor == null) {
            const anchor = gameData.weapons.find(w => w.id === enemy.weaponAnchor);
            enemy.shotsToKillAnchor = anchor && enemy.hp != null
                ? shotsToKillWithWeapon(enemy.hp, anchor)
                : 0;
        }
    });
}

export function ensureGameDataArrays() {
    const defaults = getDefaultGameData();
    if (!Array.isArray(gameData.ships)) gameData.ships = defaults.ships;
    if (!Array.isArray(gameData.shields)) gameData.shields = defaults.shields;
    ensureEnemyIds();
}
