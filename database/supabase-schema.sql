-- ============================================
-- SUPERMERCADO CLUB - SCHEMA SUPABASE COMPLETO
-- Sistema de Fidelidade Inteligente com RLS
-- ============================================

-- ================= EXTENSÕES NECESSÁRIAS =================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ================= TIPOS CUSTOMIZADOS =================
DO $$ BEGIN
    CREATE TYPE customer_nivel AS ENUM ('BRONZE', 'PRATA', 'OURO', 'DIAMANTE');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE purchase_status AS ENUM ('PENDENTE', 'APROVADA', 'RECUSADA');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE redemption_status AS ENUM ('DISPONIVEL', 'UTILIZADO', 'EXPIRADO');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE admin_role AS ENUM ('ADMINISTRADOR', 'GERENTE', 'OPERADOR');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ================= 1. TABELA DE CLIENTES =================
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    cpf TEXT UNIQUE NOT NULL,
    telefone TEXT,
    whatsapp TEXT,
    email TEXT UNIQUE,
    data_nascimento DATE,
    endereco TEXT,
    cidade TEXT,
    cep TEXT,
    nivel customer_nivel DEFAULT 'BRONZE',
    pontos_disponiveis INTEGER DEFAULT 0,
    pontos_pendentes INTEGER DEFAULT 0,
    pontos_utilizados INTEGER DEFAULT 0,
    total_gasto NUMERIC(12, 2) DEFAULT 0.00,
    quantidade_compras INTEGER DEFAULT 0,
    ultima_compra TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'ATIVO',
    qr_code_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para customers
CREATE INDEX IF NOT EXISTS idx_customers_cpf ON public.customers(cpf);
CREATE INDEX IF NOT EXISTS idx_customers_auth_user_id ON public.customers(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_nivel ON public.customers(nivel);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);

-- ================= 2. TABELA DE COMPRAS =================
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    cpf TEXT NOT NULL,
    data_compra DATE NOT NULL,
    valor NUMERIC(10, 2) NOT NULL,
    numero_cupom TEXT NOT NULL UNIQUE,
    chave_nfce TEXT UNIQUE,
    foto_cupom_url TEXT NOT NULL,
    pontos_previstos INTEGER NOT NULL,
    pontos_aprovados INTEGER DEFAULT 0,
    status purchase_status DEFAULT 'PENDENTE',
    motivo_recusa TEXT,
    observacao TEXT,
    loja TEXT,
    operador TEXT,
    analyzed_at TIMESTAMP WITH TIME ZONE,
    analyzed_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para purchases
CREATE INDEX IF NOT EXISTS idx_purchases_customer_id ON public.purchases(customer_id);
CREATE INDEX IF NOT EXISTS idx_purchases_cpf ON public.purchases(cpf);
CREATE INDEX IF NOT EXISTS idx_purchases_data_compra ON public.purchases(data_compra);
CREATE INDEX IF NOT EXISTS idx_purchases_status ON public.purchases(status);
CREATE INDEX IF NOT EXISTS idx_purchases_numero_cupom ON public.purchases(numero_cupom);

-- ================= 3. TABELA DE MOVIMENTAÇÕES DE PONTOS =================
CREATE TABLE IF NOT EXISTS public.points_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    purchase_id UUID REFERENCES public.purchases(id) ON DELETE SET NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('ganho', 'resgate', 'estorno', 'bonus', 'expiracao', 'ajuste')),
    quantidade INTEGER NOT NULL,
    descricao TEXT NOT NULL,
    saldo_anterior INTEGER DEFAULT 0,
    saldo_posterior INTEGER DEFAULT 0,
    status TEXT DEFAULT 'CONCLUIDO',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para points_transactions
CREATE INDEX IF NOT EXISTS idx_points_transactions_customer_id ON public.points_transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_points_transactions_purchase_id ON public.points_transactions(purchase_id);
CREATE INDEX IF NOT EXISTS idx_points_transactions_tipo ON public.points_transactions(tipo);
CREATE INDEX IF NOT EXISTS idx_points_transactions_created_at ON public.points_transactions(created_at);

-- ================= 4. TABELA DE RECOMPENSAS =================
CREATE TABLE IF NOT EXISTS public.rewards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_url TEXT,
    pontos_necessarios INTEGER NOT NULL,
    estoque INTEGER DEFAULT 0,
    estoque_resgatado INTEGER DEFAULT 0,
    categoria TEXT,
    validade DATE,
    status TEXT DEFAULT 'DISPONIVEL',
    data_inicio TIMESTAMP WITH TIME ZONE,
    data_fim TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para rewards
CREATE INDEX IF NOT EXISTS idx_rewards_status ON public.rewards(status);
CREATE INDEX IF NOT EXISTS idx_rewards_categoria ON public.rewards(categoria);

-- ================= 5. TABELA DE RESGATES =================
CREATE TABLE IF NOT EXISTS public.redemptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    reward_id UUID REFERENCES public.rewards(id) ON DELETE SET NULL NOT NULL,
    codigo_resgate TEXT UNIQUE NOT NULL,
    pontos_utilizados INTEGER NOT NULL,
    status redemption_status DEFAULT 'DISPONIVEL',
    data_utilizacao TIMESTAMP WITH TIME ZONE,
    data_expiracao TIMESTAMP WITH TIME ZONE,
    criado_por UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para redemptions
CREATE INDEX IF NOT EXISTS idx_redemptions_customer_id ON public.redemptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_reward_id ON public.redemptions(reward_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_status ON public.redemptions(status);
CREATE INDEX IF NOT EXISTS idx_redemptions_codigo ON public.redemptions(codigo_resgate);

-- ================= 6. TABELA DE CAMPANHAS =================
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_banner_url TEXT,
    data_inicio TIMESTAMP WITH TIME ZONE NOT NULL,
    data_fim TIMESTAMP WITH TIME ZONE NOT NULL,
    multiplicador NUMERIC(3, 2) DEFAULT 2.00,
    publico_alvo TEXT DEFAULT 'Geral',
    nivel_minimo customer_nivel,
    status TEXT DEFAULT 'ATIVA',
    usos_maximos INTEGER DEFAULT -1,
    usos_atuais INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para campaigns
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON public.campaigns(status);
CREATE INDEX IF NOT EXISTS idx_campaigns_datas ON public.campaigns(data_inicio, data_fim);

-- ================= 7. TABELA DE NOTIFICAÇÕES =================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('cliente_para_admin', 'admin_para_cliente', 'sistema')),
    titulo TEXT NOT NULL,
    mensagem TEXT NOT NULL,
    url_acao TEXT,
    lida BOOLEAN DEFAULT FALSE,
    criado_por UUID,
    lido_em TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para notifications
CREATE INDEX IF NOT EXISTS idx_notifications_customer_id ON public.notifications(customer_id);
CREATE INDEX IF NOT EXISTS idx_notifications_lida ON public.notifications(lida);
CREATE INDEX IF NOT EXISTS idx_notifications_tipo ON public.notifications(tipo);

-- ================= 8. TABELA DE USUÁRIOS ADMINISTRATIVOS =================
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    nivel_permissao admin_role DEFAULT 'OPERADOR',
    is_active BOOLEAN DEFAULT TRUE,
    ultimo_acesso TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para admin_users
CREATE INDEX IF NOT EXISTS idx_admin_users_auth_user_id ON public.admin_users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON public.admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_nivel ON public.admin_users(nivel_permissao);

-- ================= 9. TABELA DE CUPONS =================
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    codigo TEXT UNIQUE NOT NULL,
    titulo TEXT NOT NULL,
    descricao TEXT,
    tipo_desconto TEXT CHECK (tipo_desconto IN ('percentual', 'fixo')),
    valor_desconto NUMERIC(10, 2) NOT NULL,
    usos_maximos INTEGER DEFAULT -1,
    usos_atuais INTEGER DEFAULT 0,
    compra_minima NUMERIC(10, 2) DEFAULT 0.00,
    niveis_validos TEXT, -- JSON array de níveis
    data_inicio TIMESTAMP WITH TIME ZONE NOT NULL,
    data_expiracao TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'ATIVO',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para coupons
CREATE INDEX IF NOT EXISTS idx_coupons_codigo ON public.coupons(codigo);
CREATE INDEX IF NOT EXISTS idx_coupons_status ON public.coupons(status);

-- ================= 10. TABELA DE PRODUTOS =================
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    ean_code TEXT UNIQUE,
    nome TEXT NOT NULL,
    categoria TEXT,
    preco NUMERIC(10, 2),
    multiplicador_pontos NUMERIC(3, 2) DEFAULT 1.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para products
CREATE INDEX IF NOT EXISTS idx_products_ean ON public.products(ean_code);
CREATE INDEX IF NOT EXISTS idx_products_categoria ON public.products(categoria);

-- ================= 11. TABELA DE AUDITORIA =================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    usuario_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    tabela TEXT NOT NULL,
    operacao TEXT NOT NULL,
    registro_id UUID,
    valores_antigos JSONB,
    valores_novos JSONB,
    endereco_ip TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Criar índices para audit_logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_usuario_id ON public.audit_logs(usuario_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tabela ON public.audit_logs(tabela);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at);

-- ================= STORAGE BUCKET CONFIGURATION =================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('purchase-receipts', 'purchase-receipts', true)
ON CONFLICT (id) DO NOTHING;

-- ================= ROW LEVEL SECURITY (RLS) =================
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ================= POLÍTICAS RLS: CUSTOMERS =================
DROP POLICY IF EXISTS "Clientes podem ver seu próprio perfil" ON public.customers;
CREATE POLICY "Clientes podem ver seu próprio perfil" ON public.customers
    FOR SELECT USING (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Clientes podem atualizar seu próprio perfil" ON public.customers;
CREATE POLICY "Clientes podem atualizar seu próprio perfil" ON public.customers
    FOR UPDATE USING (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Administradores têm acesso completo a customers" ON public.customers;
CREATE POLICY "Administradores têm acesso completo a customers" ON public.customers
    FOR ALL USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

-- ================= POLÍTICAS RLS: PURCHASES =================
DROP POLICY IF EXISTS "Clientes podem ver e criar suas próprias compras" ON public.purchases;
CREATE POLICY "Clientes podem ver e criar suas próprias compras" ON public.purchases
    FOR ALL USING (
        customer_id IN (SELECT id FROM public.customers WHERE auth_user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Administradores têm acesso completo a purchases" ON public.purchases;
CREATE POLICY "Administradores têm acesso completo a purchases" ON public.purchases
    FOR ALL USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

-- ================= POLÍTICAS RLS: POINTS_TRANSACTIONS =================
DROP POLICY IF EXISTS "Clientes podem ver seu histórico de pontos" ON public.points_transactions;
CREATE POLICY "Clientes podem ver seu histórico de pontos" ON public.points_transactions
    FOR SELECT USING (
        customer_id IN (SELECT id FROM public.customers WHERE auth_user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Administradores gerenciam points_transactions" ON public.points_transactions;
CREATE POLICY "Administradores gerenciam points_transactions" ON public.points_transactions
    FOR ALL USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

-- ================= POLÍTICAS RLS: REWARDS =================
DROP POLICY IF EXISTS "Todos podem ver recompensas disponíveis" ON public.rewards;
CREATE POLICY "Todos podem ver recompensas disponíveis" ON public.rewards
    FOR SELECT USING (status = 'DISPONIVEL');

DROP POLICY IF EXISTS "Administradores gerenciam rewards" ON public.rewards;
CREATE POLICY "Administradores gerenciam rewards" ON public.rewards
    FOR ALL USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

-- ================= POLÍTICAS RLS: REDEMPTIONS =================
DROP POLICY IF EXISTS "Clientes podem ver seus próprios resgates" ON public.redemptions;
CREATE POLICY "Clientes podem ver seus próprios resgates" ON public.redemptions
    FOR SELECT USING (
        customer_id IN (SELECT id FROM public.customers WHERE auth_user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Administradores gerenciam redemptions" ON public.redemptions;
CREATE POLICY "Administradores gerenciam redemptions" ON public.redemptions
    FOR ALL USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

-- ================= POLÍTICAS RLS: CAMPAIGNS =================
DROP POLICY IF EXISTS "Todos podem ver campanhas ativas" ON public.campaigns;
CREATE POLICY "Todos podem ver campanhas ativas" ON public.campaigns
    FOR SELECT USING (
        status = 'ATIVA' AND 
        CURRENT_TIMESTAMP BETWEEN data_inicio AND data_fim
    );

DROP POLICY IF EXISTS "Administradores gerenciam campaigns" ON public.campaigns;
CREATE POLICY "Administradores gerenciam campaigns" ON public.campaigns
    FOR ALL USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

-- ================= POLÍTICAS RLS: NOTIFICATIONS =================
DROP POLICY IF EXISTS "Clientes veem suas próprias notificações" ON public.notifications;
CREATE POLICY "Clientes veem suas próprias notificações" ON public.notifications
    FOR SELECT USING (
        customer_id IN (SELECT id FROM public.customers WHERE auth_user_id = auth.uid())
        OR auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

DROP POLICY IF EXISTS "Administradores gerenciam notifications" ON public.notifications;
CREATE POLICY "Administradores gerenciam notifications" ON public.notifications
    FOR ALL USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE is_active = TRUE)
    );

-- ================= POLÍTICAS RLS: ADMIN_USERS =================
DROP POLICY IF EXISTS "Administradores veem admin_users" ON public.admin_users;
CREATE POLICY "Administradores veem admin_users" ON public.admin_users
    FOR SELECT USING (
        auth.uid() IN (SELECT auth_user_id FROM public.admin_users WHERE nivel_permissao = 'ADMINISTRADOR'::admin_role)
    );

-- ================= FUNÇÕES E TRIGGERS =================

-- Função: Atualizar nível do cliente baseado em pontos
CREATE OR REPLACE FUNCTION public.update_customer_level()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.pontos_disponiveis >= 10000 THEN
        NEW.nivel := 'DIAMANTE'::customer_nivel;
    ELSIF NEW.pontos_disponiveis >= 5000 THEN
        NEW.nivel := 'OURO'::customer_nivel;
    ELSIF NEW.pontos_disponiveis >= 2000 THEN
        NEW.nivel := 'PRATA'::customer_nivel;
    ELSE
        NEW.nivel := 'BRONZE'::customer_nivel;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Atualizar nível do cliente
DROP TRIGGER IF EXISTS trg_update_customer_level ON public.customers;
CREATE TRIGGER trg_update_customer_level
    BEFORE UPDATE OF pontos_disponiveis ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION public.update_customer_level();

-- Função: Atualizar timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para update_updated_at
DROP TRIGGER IF EXISTS trg_customers_updated_at ON public.customers;
CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_purchases_updated_at ON public.purchases;
CREATE TRIGGER trg_purchases_updated_at BEFORE UPDATE ON public.purchases FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_rewards_updated_at ON public.rewards;
CREATE TRIGGER trg_rewards_updated_at BEFORE UPDATE ON public.rewards FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_redemptions_updated_at ON public.redemptions;
CREATE TRIGGER trg_redemptions_updated_at BEFORE UPDATE ON public.redemptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_campaigns_updated_at ON public.campaigns;
CREATE TRIGGER trg_campaigns_updated_at BEFORE UPDATE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_coupons_updated_at ON public.coupons;
CREATE TRIGGER trg_coupons_updated_at BEFORE UPDATE ON public.coupons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_admin_users_updated_at ON public.admin_users;
CREATE TRIGGER trg_admin_users_updated_at BEFORE UPDATE ON public.admin_users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ================= VIEWS ÚTEIS =================

-- View: Estatísticas do Dashboard
DROP VIEW IF EXISTS public.vw_dashboard_stats;
CREATE VIEW public.vw_dashboard_stats AS
SELECT 
    (SELECT COUNT(*) FROM public.customers WHERE status = 'ATIVO') as total_clientes,
    (SELECT COALESCE(SUM(pontos_disponiveis), 0) FROM public.customers) as total_pontos_distribuidos,
    (SELECT COALESCE(SUM(pontos_utilizados), 0) FROM public.customers) as total_pontos_resgatados,
    (SELECT COALESCE(SUM(valor), 0) FROM public.purchases WHERE status = 'APROVADA') as valor_movimentado,
    (SELECT COUNT(*) FROM public.purchases WHERE status = 'APROVADA') as total_compras,
    (SELECT COUNT(*) FROM public.redemptions WHERE status = 'UTILIZADO') as total_resgates;

-- View: Clientes Principais
DROP VIEW IF EXISTS public.vw_top_customers;
CREATE VIEW public.vw_top_customers AS
SELECT 
    c.id,
    c.nome,
    c.cpf,
    c.nivel,
    c.total_gasto,
    c.pontos_disponiveis,
    c.quantidade_compras,
    ROW_NUMBER() OVER (ORDER BY c.total_gasto DESC) as posicao
FROM public.customers c
WHERE c.status = 'ATIVO'
LIMIT 100;

-- ================= DADOS INICIAIS =================

-- Inserir campanha de boas-vindas (exemplo)
INSERT INTO public.campaigns (nome, descricao, data_inicio, data_fim, multiplicador, status)
VALUES (
    'Bem-vindo ao Club Super',
    'Ganhe pontos em dobro na sua primeira compra',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '30 days',
    2.00,
    'ATIVA'
)
ON CONFLICT DO NOTHING;

-- Inserir recompensas padrão (exemplos)
INSERT INTO public.rewards (nome, descricao, pontos_necessarios, categoria, status)
VALUES 
    ('Vale R$50', 'Vale de R$50 para próximas compras', 5000, 'Vale', 'DISPONIVEL'),
    ('Vale R$100', 'Vale de R$100 para próximas compras', 10000, 'Vale', 'DISPONIVEL'),
    ('Brinde Exclusivo', 'Brinde especial para clientes premiados', 2000, 'Brinde', 'DISPONIVEL'),
    ('Desconto 20%', 'Desconto exclusivo de 20% em uma compra', 7500, 'Desconto', 'DISPONIVEL')
ON CONFLICT DO NOTHING;

COMMIT;
