// ============================================
// SUPABASE CLIENT - Inicialização e Configuração
// ============================================

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || "https://your-project.supabase.co";
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || "your-anon-key";

// Validar se as chaves estão configuradas
if (!SUPABASE_URL || !SUPABASE_ANON_KEY || SUPABASE_URL.includes("your-project")) {
    console.error("❌ Supabase não configurado. Configure .env.local com VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY");
}

// Criar cliente Supabase
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ============================================
// Classe para gerenciar autenticação
// ============================================
class AuthService {
    static async getCurrentSession() {
        const { data: { session }, error } = await supabaseClient.auth.getSession();
        return { session, error };
    }

    static async getCurrentUser() {
        const { data: { user }, error } = await supabaseClient.auth.getUser();
        return { user, error };
    }

    static async signUp(email, password) {
        const { data, error } = await supabaseClient.auth.signUp({
            email,
            password,
        });
        return { data, error };
    }

    static async signIn(email, password) {
        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email,
            password,
        });
        return { data, error };
    }

    static async signOut() {
        const { error } = await supabaseClient.auth.signOut();
        return { error };
    }

    static async resetPassword(email) {
        const { data, error } = await supabaseClient.auth.resetPasswordForEmail(email);
        return { data, error };
    }

    static onAuthStateChange(callback) {
        return supabaseClient.auth.onAuthStateChange(callback);
    }
}

// ============================================
// Classe para gerenciar dados em tempo real
// ============================================
class RealtimeService {
    static subscribeToCustomer(customerId, callback) {
        return supabaseClient
            .channel(`customer:${customerId}`)
            .on(
                'postgres_changes',
                {
                    event: 'UPDATE',
                    schema: 'public',
                    table: 'customers',
                    filter: `id=eq.${customerId}`,
                },
                callback
            )
            .subscribe();
    }

    static subscribeToPurchases(customerId, callback) {
        return supabaseClient
            .channel(`purchases:${customerId}`)
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'purchases',
                    filter: `customer_id=eq.${customerId}`,
                },
                callback
            )
            .subscribe();
    }

    static subscribeToNotifications(customerId, callback) {
        return supabaseClient
            .channel(`notifications:${customerId}`)
            .on(
                'postgres_changes',
                {
                    event: 'INSERT',
                    schema: 'public',
                    table: 'notifications',
                    filter: `customer_id=eq.${customerId}`,
                },
                callback
            )
            .subscribe();
    }

    static unsubscribe(subscription) {
        return supabaseClient.removeChannel(subscription);
    }
}

// ============================================
// Classe para gerenciar pontos
// ============================================
class PointsService {
    static async getCustomerPoints(customerId) {
        const { data, error } = await supabaseClient
            .from('customers')
            .select('pontos_disponiveis, pontos_pendentes, pontos_utilizados, nivel')
            .eq('id', customerId)
            .single();
        return { data, error };
    }

    static async getPointsHistory(customerId, limit = 20) {
        const { data, error } = await supabaseClient
            .from('points_transactions')
            .select('*')
            .eq('customer_id', customerId)
            .order('created_at', { ascending: false })
            .limit(limit);
        return { data, error };
    }
}

// Exportar para uso global ou como módulo
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { supabaseClient, AuthService, RealtimeService, PointsService };
}
