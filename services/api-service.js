// ============================================
// API SERVICE - Camada Centralizada de Requisições
// ============================================

class ApiService {
    constructor(supabaseClient) {
        this.client = supabaseClient;
    }

    // ============================================
    // CLIENTES (Customers)
    // ============================================

    async getCustomer(customerId) {
        try {
            const { data, error } = await this.client
                .from('customers')
                .select('*')
                .eq('id', customerId)
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar cliente:', error);
            return { success: false, error: error.message };
        }
    }

    async getCustomerByAuthId(authUserId) {
        try {
            const { data, error } = await this.client
                .from('customers')
                .select('*')
                .eq('auth_user_id', authUserId)
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar cliente por auth_user_id:', error);
            return { success: false, error: error.message };
        }
    }

    async updateCustomer(customerId, updates) {
        try {
            const { data, error } = await this.client
                .from('customers')
                .update(updates)
                .eq('id', customerId)
                .select()
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao atualizar cliente:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // COMPRAS (Purchases)
    // ============================================

    async createPurchase(purchaseData) {
        try {
            const { data, error } = await this.client
                .from('purchases')
                .insert([purchaseData])
                .select()
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao criar compra:', error);
            return { success: false, error: error.message };
        }
    }

    async getPurchases(customerId, limit = 50) {
        try {
            const { data, error } = await this.client
                .from('purchases')
                .select('*')
                .eq('customer_id', customerId)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar compras:', error);
            return { success: false, error: error.message };
        }
    }

    async getPurchaseById(purchaseId) {
        try {
            const { data, error } = await this.client
                .from('purchases')
                .select('*')
                .eq('id', purchaseId)
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar compra:', error);
            return { success: false, error: error.message };
        }
    }

    async updatePurchase(purchaseId, updates) {
        try {
            const { data, error } = await this.client
                .from('purchases')
                .update(updates)
                .eq('id', purchaseId)
                .select()
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao atualizar compra:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // ARMAZENAMENTO (Storage)
    // ============================================

    async uploadReceiptImage(file, customerId) {
        try {
            const fileExt = file.name.split('.').pop();
            const fileName = `${customerId}/${Date.now()}.${fileExt}`;
            const filePath = `purchase-receipts/${fileName}`;

            const { data, error: uploadError } = await this.client.storage
                .from('purchase-receipts')
                .upload(filePath, file);

            if (uploadError) throw uploadError;

            const { data: urlData } = this.client.storage
                .from('purchase-receipts')
                .getPublicUrl(filePath);

            return { success: true, url: urlData.publicUrl, path: filePath };
        } catch (error) {
            console.error('Erro ao fazer upload de imagem:', error);
            return { success: false, error: error.message };
        }
    }

    async deleteReceiptImage(filePath) {
        try {
            const { error } = await this.client.storage
                .from('purchase-receipts')
                .remove([filePath]);

            if (error) throw error;
            return { success: true };
        } catch (error) {
            console.error('Erro ao deletar imagem:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // PONTOS (Points Transactions)
    // ============================================

    async getPointsHistory(customerId, limit = 50) {
        try {
            const { data, error } = await this.client
                .from('points_transactions')
                .select('*')
                .eq('customer_id', customerId)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar histórico de pontos:', error);
            return { success: false, error: error.message };
        }
    }

    async createPointsTransaction(transactionData) {
        try {
            const { data, error } = await this.client
                .from('points_transactions')
                .insert([transactionData])
                .select()
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao criar transação de pontos:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // RECOMPENSAS (Rewards)
    // ============================================

    async getAvailableRewards() {
        try {
            const { data, error } = await this.client
                .from('rewards')
                .select('*')
                .eq('status', 'DISPONIVEL')
                .order('pontos_necessarios', { ascending: true });

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar recompensas:', error);
            return { success: false, error: error.message };
        }
    }

    async getRewardById(rewardId) {
        try {
            const { data, error } = await this.client
                .from('rewards')
                .select('*')
                .eq('id', rewardId)
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar recompensa:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // RESGATES (Redemptions)
    // ============================================

    async createRedemption(redemptionData) {
        try {
            const { data, error } = await this.client
                .from('redemptions')
                .insert([redemptionData])
                .select()
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao criar resgate:', error);
            return { success: false, error: error.message };
        }
    }

    async getRedemptions(customerId, limit = 50) {
        try {
            const { data, error } = await this.client
                .from('redemptions')
                .select('*, rewards(*)')
                .eq('customer_id', customerId)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar resgates:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // NOTIFICAÇÕES (Notifications)
    // ============================================

    async getNotifications(customerId, limit = 20, unreadOnly = false) {
        try {
            let query = this.client
                .from('notifications')
                .select('*')
                .eq('customer_id', customerId);

            if (unreadOnly) {
                query = query.eq('lida', false);
            }

            const { data, error } = await query
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar notificações:', error);
            return { success: false, error: error.message };
        }
    }

    async markNotificationAsRead(notificationId) {
        try {
            const { data, error } = await this.client
                .from('notifications')
                .update({ lida: true, lido_em: new Date().toISOString() })
                .eq('id', notificationId)
                .select()
                .single();

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao marcar notificação como lida:', error);
            return { success: false, error: error.message };
        }
    }

    async getUnreadNotificationsCount(customerId) {
        try {
            const { count, error } = await this.client
                .from('notifications')
                .select('*', { count: 'exact', head: true })
                .eq('customer_id', customerId)
                .eq('lida', false);

            if (error) throw error;
            return { success: true, count };
        } catch (error) {
            console.error('Erro ao contar notificações não lidas:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // CAMPANHAS (Campaigns)
    // ============================================

    async getActiveCampaigns() {
        try {
            const now = new Date().toISOString();
            const { data, error } = await this.client
                .from('campaigns')
                .select('*')
                .eq('status', 'ATIVA')
                .lte('data_inicio', now)
                .gte('data_fim', now)
                .order('data_inicio', { ascending: false });

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar campanhas ativas:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // CUPONS (Coupons)
    // ============================================

    async getActiveCoupons(customerLevel) {
        try {
            const now = new Date().toISOString();
            const { data, error } = await this.client
                .from('coupons')
                .select('*')
                .eq('status', 'ATIVO')
                .lte('data_inicio', now)
                .gte('data_expiracao', now)
                .order('data_inicio', { ascending: false });

            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            console.error('Erro ao buscar cupons:', error);
            return { success: false, error: error.message };
        }
    }

    // ============================================
    // UTILITÁRIOS
    // ============================================

    calculatePointsFromValue(value, multiplier = 1) {
        return Math.floor(value * 10 * multiplier);
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('pt-BR', {
            style: 'currency',
            currency: 'BRL',
        }).format(value);
    }

    formatDate(date) {
        return new Intl.DateTimeFormat('pt-BR').format(new Date(date));
    }

    formatDateTime(date) {
        return new Intl.DateTimeFormat('pt-BR', {
            dateStyle: 'short',
            timeStyle: 'short',
        }).format(new Date(date));
    }
}

// Exportar instância global se Supabase estiver disponível
if (typeof window !== 'undefined' && window.supabaseClient) {
    window.apiService = new ApiService(window.supabaseClient);
}

// Exportar para uso em módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ApiService;
}
