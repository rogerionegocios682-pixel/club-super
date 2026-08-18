// ============================================
// PORTAL DO CLIENTE - Lógica Principal
// ============================================

class ClientPortalApp {
    constructor() {
        this.currentCustomer = null;
        this.authUser = null;
        this.purchaseSubscription = null;
        this.customerSubscription = null;
        this.notificationSubscription = null;
        this.init();
    }

    // ============================================
    // INICIALIZAÇÃO
    // ============================================

    async init() {
        console.log('🚀 Inicializando Portal do Cliente...');
        
        // Verificar se Supabase está configurado
        if (!window.supabaseClient) {
            this.showToast('❌ Erro: Supabase não foi inicializado', 'error');
            return;
        }

        // Verificar autenticação
        const { session, error } = await AuthService.getCurrentSession();
        
        if (error || !session) {
            console.log('Usuário não autenticado. Redirecionando para login...');
            window.location.href = 'login.html';
            return;
        }

        this.authUser = session.user;
        await this.loadClientData();
        this.setupEventListeners();
        this.setupRealtimeListeners();
    }

    // ============================================
    // CARREGAMENTO DE DADOS
    // ============================================

    async loadClientData() {
        try {
            const result = await window.apiService.getCustomerByAuthId(this.authUser.id);
            
            if (!result.success) {
                this.showToast('❌ Erro ao carregar dados do cliente', 'error');
                return;
            }

            this.currentCustomer = result.data;
            this.updateUIWithCustomerData();
            await this.loadPurchasesHistory();
            await this.loadNotifications();
        } catch (error) {
            console.error('Erro ao carregar dados do cliente:', error);
            this.showToast('❌ Erro ao carregar dados', 'error');
        }
    }

    updateUIWithCustomerData() {
        if (!this.currentCustomer) return;

        // Atualizar nome
        const nameElement = document.getElementById('client-name');
        if (nameElement) {
            const firstName = this.currentCustomer.nome.split(' ')[0];
            nameElement.textContent = firstName;
        }

        // Atualizar saldo de pontos
        const balanceElement = document.getElementById('client-balance');
        if (balanceElement) {
            balanceElement.textContent = `⭐ ${this.currentCustomer.pontos_disponiveis.toLocaleString('pt-BR')} PONTOS`;
        }

        // Atualizar nível
        const levelElement = document.getElementById('client-level');
        if (levelElement) {
            levelElement.textContent = this.currentCustomer.nivel;
        }

        // Atualizar pontos pendentes
        const pendingElement = document.getElementById('client-pending');
        if (pendingElement) {
            pendingElement.textContent = `${this.currentCustomer.pontos_pendentes} pts`;
        }

        console.log('✅ Dados do cliente carregados:', this.currentCustomer);
    }

    async loadPurchasesHistory() {
        try {
            const result = await window.apiService.getPurchases(this.currentCustomer.id, 50);
            
            if (!result.success || !result.data) {
                this.showPurchasesEmpty();
                return;
            }

            this.renderPurchasesHistory(result.data);
        } catch (error) {
            console.error('Erro ao carregar histórico de compras:', error);
            this.showToast('❌ Erro ao carregar histórico', 'error');
        }
    }

    renderPurchasesHistory(purchases) {
        const container = document.getElementById('purchases-history-list');
        if (!container) return;

        if (purchases.length === 0) {
            this.showPurchasesEmpty();
            return;
        }

        container.innerHTML = purchases.map(purchase => `
            <div class="purchase-item">
                <div class="purchase-info">
                    <strong>Cupom #${purchase.numero_cupom}</strong><br>
                    <span class="purchase-date">${window.apiService.formatDate(purchase.data_compra)}</span>
                </div>
                <div class="purchase-details">
                    <span class="purchase-value">R$ ${purchase.valor.toFixed(2)}</span><br>
                    <span class="purchase-points">+${purchase.pontos_previstos} pts</span>
                </div>
                <div class="purchase-status">
                    <span class="badge badge-${purchase.status.toLowerCase()}">${purchase.status}</span>
                </div>
            </div>
        `).join('');
    }

    showPurchasesEmpty() {
        const container = document.getElementById('purchases-history-list');
        if (container) {
            container.innerHTML = '<p style="color: var(--text-muted); text-align: center; padding: 20px;">Nenhuma compra registrada ainda.</p>';
        }
    }

    async loadNotifications() {
        try {
            const result = await window.apiService.getUnreadNotificationsCount(this.currentCustomer.id);
            
            if (result.success && result.count > 0) {
                const badge = document.getElementById('notification-badge');
                if (badge) {
                    badge.textContent = result.count;
                    badge.style.display = 'inline-block';
                }
            }
        } catch (error) {
            console.error('Erro ao carregar notificações:', error);
        }
    }

    // ============================================
    // UPLOAD E ENVIO DE COMPRA
    // ============================================

    setupEventListeners() {
        const purchaseForm = document.getElementById('purchase-form');
        const photoInput = document.getElementById('p-foto');

        if (purchaseForm) {
            purchaseForm.addEventListener('submit', (e) => this.handlePurchaseSubmit(e));
        }

        if (photoInput) {
            photoInput.addEventListener('change', (e) => this.previewImage(e));
        }
    }

    previewImage(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            const imgOutput = document.getElementById('img-output');
            const previewBox = document.getElementById('preview-box');
            
            if (imgOutput && previewBox) {
                imgOutput.src = e.target.result;
                imgOutput.style.display = 'block';
                previewBox.style.backgroundImage = `url(${e.target.result})`;
                previewBox.style.backgroundSize = 'cover';
                previewBox.style.backgroundPosition = 'center';
            }
        };
        reader.readAsDataURL(file);
    }

    async handlePurchaseSubmit(event) {
        event.preventDefault();

        if (!this.currentCustomer) {
            this.showToast('❌ Erro: Dados do cliente não carregados', 'error');
            return;
        }

        try {
            this.showToast('📤 Enviando compra...');

            const valor = parseFloat(document.getElementById('p-valor').value);
            const numeroCupom = document.getElementById('p-cupom').value;
            const dataCompra = document.getElementById('p-data').value;
            const fileInput = document.getElementById('p-foto').files[0];

            // Validações
            if (!valor || valor <= 0) {
                this.showToast('❌ Valor inválido', 'error');
                return;
            }

            if (!fileInput) {
                this.showToast('❌ Selecione uma foto do cupom', 'error');
                return;
            }

            // Upload da imagem
            this.showToast('📸 Enviando foto...');
            const uploadResult = await window.apiService.uploadReceiptImage(fileInput, this.currentCustomer.id);

            if (!uploadResult.success) {
                this.showToast(`❌ Erro ao enviar foto: ${uploadResult.error}`, 'error');
                return;
            }

            // Calcular pontos
            const pontosPrevistos = window.apiService.calculatePointsFromValue(valor);

            // Criar compra
            this.showToast('💾 Registrando compra...');
            const purchaseResult = await window.apiService.createPurchase({
                customer_id: this.currentCustomer.id,
                cpf: this.currentCustomer.cpf,
                data_compra: dataCompra,
                valor: valor,
                numero_cupom: numeroCupom,
                foto_cupom_url: uploadResult.url,
                pontos_previstos: pontosPrevistos,
                status: 'PENDENTE'
            });

            if (!purchaseResult.success) {
                this.showToast(`❌ Erro ao registrar compra: ${purchaseResult.error}`, 'error');
                return;
            }

            // Sucesso
            this.showToast('✅ Compra enviada com sucesso! Aguardando análise do supermercado.', 'success');
            
            // Limpar formulário
            document.getElementById('purchase-form').reset();
            document.getElementById('img-output').style.display = 'none';
            document.getElementById('preview-box').style.backgroundImage = 'none';

            // Recarregar histórico
            await this.loadPurchasesHistory();

        } catch (error) {
            console.error('Erro ao enviar compra:', error);
            this.showToast(`❌ Erro: ${error.message}`, 'error');
        }
    }

    // ============================================
    // LISTENERS EM TEMPO REAL (Realtime)
    // ============================================

    setupRealtimeListeners() {
        if (!this.currentCustomer) return;

        // Ouvir atualizações do cliente
        this.customerSubscription = RealtimeService.subscribeToCustomer(
            this.currentCustomer.id,
            (payload) => this.handleCustomerUpdate(payload)
        );

        // Ouvir novas compras
        this.purchaseSubscription = RealtimeService.subscribeToPurchases(
            this.currentCustomer.id,
            (payload) => this.handlePurchaseUpdate(payload)
        );

        // Ouvir notificações
        this.notificationSubscription = RealtimeService.subscribeToNotifications(
            this.currentCustomer.id,
            (payload) => this.handleNotificationUpdate(payload)
        );

        console.log('✅ Realtime listeners configurados');
    }

    handleCustomerUpdate(payload) {
        console.log('🔄 Atualização do cliente recebida:', payload);
        
        const updated = payload.new;
        this.currentCustomer = updated;
        this.updateUIWithCustomerData();
        
        // Mostrar notificação de pontos atualizados
        if (payload.old.pontos_disponiveis !== updated.pontos_disponiveis) {
            const pontosGanhos = updated.pontos_disponiveis - payload.old.pontos_disponiveis;
            this.showToast(`🎉 +${pontosGanhos} pontos adicionados!`, 'success');
        }
    }

    handlePurchaseUpdate(payload) {
        console.log('🔄 Atualização de compra recebida:', payload);
        
        if (payload.eventType === 'UPDATE') {
            const purchase = payload.new;
            
            if (purchase.status === 'APROVADA') {
                this.showToast(`✅ Compra #${purchase.numero_cupom} foi aprovada!`, 'success');
            } else if (purchase.status === 'RECUSADA') {
                this.showToast(`❌ Compra #${purchase.numero_cupom} foi recusada. Motivo: ${purchase.motivo_recusa}`, 'error');
            }
        }
        
        this.loadPurchasesHistory();
    }

    handleNotificationUpdate(payload) {
        console.log('🔔 Nova notificação recebida:', payload);
        const notification = payload.new;
        this.showToast(`📢 ${notification.titulo}: ${notification.mensagem}`);
        this.loadNotifications();
    }

    // ============================================
    // UTILITÁRIOS
    // ============================================

    showToast(message, type = 'info') {
        const toastElement = document.getElementById('toast');
        if (!toastElement) return;

        toastElement.textContent = message;
        toastElement.className = `toast toast-${type}`;
        toastElement.style.display = 'block';

        setTimeout(() => {
            toastElement.style.display = 'none';
        }, 3500);
    }

    async logout() {
        try {
            const { error } = await AuthService.signOut();
            
            if (error) {
                this.showToast('❌ Erro ao sair', 'error');
                return;
            }

            // Limpar subscriptions
            if (this.customerSubscription) {
                RealtimeService.unsubscribe(this.customerSubscription);
            }
            if (this.purchaseSubscription) {
                RealtimeService.unsubscribe(this.purchaseSubscription);
            }
            if (this.notificationSubscription) {
                RealtimeService.unsubscribe(this.notificationSubscription);
            }

            window.location.href = 'login.html';
        } catch (error) {
            console.error('Erro ao fazer logout:', error);
            this.showToast('❌ Erro ao sair', 'error');
        }
    }

    // ============================================
    // MÉTODOS PÚBLICOS
    // ============================================

    async viewRewards() {
        try {
            const result = await window.apiService.getAvailableRewards();
            
            if (!result.success) {
                this.showToast('❌ Erro ao carregar recompensas', 'error');
                return;
            }

            console.log('Recompensas disponíveis:', result.data);
            this.showToast(`📦 ${result.data.length} recompensas disponíveis`);
        } catch (error) {
            console.error('Erro ao visualizar recompensas:', error);
            this.showToast('❌ Erro ao carregar recompensas', 'error');
        }
    }

    async viewNotifications() {
        try {
            const result = await window.apiService.getNotifications(this.currentCustomer.id, 20);
            
            if (!result.success) {
                this.showToast('❌ Erro ao carregar notificações', 'error');
                return;
            }

            console.log('Notificações:', result.data);
            this.showToast(`🔔 ${result.data.length} notificações`);
        } catch (error) {
            console.error('Erro ao visualizar notificações:', error);
            this.showToast('❌ Erro ao carregar notificações', 'error');
        }
    }

    async viewPointsHistory() {
        try {
            const result = await window.apiService.getPointsHistory(this.currentCustomer.id, 50);
            
            if (!result.success) {
                this.showToast('❌ Erro ao carregar histórico', 'error');
                return;
            }

            console.log('Histórico de pontos:', result.data);
            this.showToast(`📊 ${result.data.length} transações de pontos`);
        } catch (error) {
            console.error('Erro ao visualizar histórico:', error);
            this.showToast('❌ Erro ao carregar histórico', 'error');
        }
    }
}

// ============================================
// INICIALIZAÇÃO GLOBAL
// ============================================

let clientPortal = null;

document.addEventListener('DOMContentLoaded', () => {
    clientPortal = new ClientPortalApp();
});

// Funções globais para onclick
function logoutClient() {
    if (clientPortal) {
        clientPortal.logout();
    }
}

function viewRewards() {
    if (clientPortal) {
        clientPortal.viewRewards();
    }
}

function viewNotifications() {
    if (clientPortal) {
        clientPortal.viewNotifications();
    }
}

function viewPointsHistory() {
    if (clientPortal) {
        clientPortal.viewPointsHistory();
    }
}

function previewImage(event) {
    if (clientPortal) {
        clientPortal.previewImage(event);
    }
}

function submitPurchase(event) {
    if (clientPortal) {
        clientPortal.handlePurchaseSubmit(event);
    }
}
