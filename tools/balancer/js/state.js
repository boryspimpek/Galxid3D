export const STORAGE_KEY = 'galaxid3d_balancer';

export function getDefaultGameData() {
    return {
        ships: [
            { id: "statek_startowy", name: "Statek Startowy", armor: 50 }
        ],
        shields: [
            { id: "tarcza_podstawowa", name: "Tarcza Podstawowa", shield: 50 }
        ],
        generators: [
            { id: "generator_t1", name: "Generator T1", maxEnergy: 300, regen: 30 },
            { id: "generator_t2", name: "Generator T2", maxEnergy: 400, regen: 40 }
        ],
        weapons: [
            { id: "laser_plazmowy_t1", name: "Laser Plazmowy T1", generatorId: "generator_t1", dmg: 10, cooldown: 0.2, cost: 10, dps: 50 },
            { id: "ciezkie_dzialo_t2", name: "Ciężkie Działo T2", generatorId: "generator_t2", dmg: 60, cooldown: 0.4, cost: 25, dps: 150 }
        ],
        enemies: [
            { id: "mieso_armatnie_dron", name: "Mięso Armatnie (Dron)", shipId: "statek_startowy", shieldId: "tarcza_podstawowa", hp: 10, projectileDmg: 5, attackCooldown: 1.0 },
            { id: "standardowy_mysliwiec", name: "Standardowy Myśliwiec", shipId: "statek_startowy", shieldId: "tarcza_podstawowa", hp: 25, projectileDmg: 10, attackCooldown: 0.5 }
        ]
    };
}

export let gameData = getDefaultGameData();
export let currentSimEnergy = 300;
export let editingGeneratorId = null;
export let editingWeaponId = null;
export let editingEnemyId = null;
export let editingShipId = null;
export let editingShieldId = null;
export let pendingFormRestore = null;

export function resetEditingIds() {
    editingGeneratorId = null;
    editingWeaponId = null;
    editingEnemyId = null;
    editingShipId = null;
    editingShieldId = null;
}

export function setGameData(data) {
    gameData = data;
}

export function setPendingFormRestore(form) {
    pendingFormRestore = form;
}

export function clearPendingFormRestore() {
    pendingFormRestore = null;
}

export function setEditingGeneratorId(id) { editingGeneratorId = id; }
export function setEditingWeaponId(id) { editingWeaponId = id; }
export function setEditingEnemyId(id) { editingEnemyId = id; }
export function setEditingShipId(id) { editingShipId = id; }
export function setEditingShieldId(id) { editingShieldId = id; }
export function setCurrentSimEnergy(value) { currentSimEnergy = value; }
