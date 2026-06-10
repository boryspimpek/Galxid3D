const TAB_KEY = 'galaxid3d_balancer_tab';

export function initTabs() {
    const buttons = document.querySelectorAll('[data-tab]');
    const panels = document.querySelectorAll('[data-tab-panel]');

    function activate(tabId) {
        buttons.forEach(btn => {
            btn.classList.toggle('tab-active', btn.dataset.tab === tabId);
        });
        panels.forEach(panel => {
            panel.hidden = panel.dataset.tabPanel !== tabId;
        });
        try {
            localStorage.setItem(TAB_KEY, tabId);
        } catch (_) { /* ignore */ }
    }

    buttons.forEach(btn => {
        btn.addEventListener('click', () => activate(btn.dataset.tab));
    });

    let initial = 'player';
    try {
        const saved = localStorage.getItem(TAB_KEY);
        if (saved && [...buttons].some(b => b.dataset.tab === saved)) {
            initial = saved;
        }
    } catch (_) { /* ignore */ }

    activate(initial);
}
