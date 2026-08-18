supereconomicos-clube/
├── 📱 cliente/                          # Portal do Consumidor
│   ├── index.html                       # Portal Principal (Saldo, Histórico, Resgates)
│   ├── login.html                       # Autenticação Cliente via Supabase
│   ├── register.html                    # Cadastro de Novo Cliente
│   ├── upload-receipt.html              # Upload de Cupom com Câmera
│   ├── qrcode.html                      # QR Code Virtual do Cliente
│   ├── rewards.html                     # Recompensas Disponíveis
│   ├── redemptions.html                 # Histórico de Resgates
│   ├── statement.html                   # Extrato de Pontos
│   ├── profile.html                     # Editar Perfil
│   ├── notifications.html               # Central de Notificações
│   ├── css/
│   │   ├── style.css                    # Estilos principais
│   │   └── responsive.css               # Mobile-first
│   └── js/
│       ├── auth.js                      # Gerenciar autenticação
│       ├── api.js                       # Requisições Supabase
│       ├── utils.js                     # Funções utilitárias
│       └── app.js                       # Lógica principal
│
├── 📊 admin/                            # Painel Administrativo
│   ├── index.html                       # Dashboard Principal
│   ├── login.html                       # Acesso Seguro Admin
│   ├── customers.html                   # Gestão de Clientes
│   ├── purchases.html                   # Análise de Compras Pendentes
│   ├── points.html                      # Controle de Pontos
│   ├── rewards.html                     # Gerenciar Recompensas
│   ├── campaigns.html                   # Campanhas Promocionais
│   ├── coupons.html                     # Sistema de Cupons
│   ├── reports.html                     # Relatórios Analíticos
│   ├── users.html                       # Gestão de Usuários Admin
│   ├── settings.html                    # Configurações do Sistema
│   ├── css/
│   │   ├── admin-theme.css              # Tema Admin
│   │   └── dashboard.css                # Dashboard específico
│   └── js/
│       ├── admin-auth.js                # Autenticação Admin RLS
│       ├── dashboard.js                 # Lógica do Dashboard
│       ├── purchases-handler.js         # Aprovação/Recusa de Compras
│       ├── realtime-sync.js             # Sync em Tempo Real (Supabase)
│       └── charts.js                    # Gráficos e Dados
│
├── 🎨 assets/                           # Recursos Estáticos
│   ├── images/
│   │   ├── logo.png
│   │   ├── logo-dark.png
│   │   ├── mascote.png
│   │   ├── hero-banner.png
│   │   └── placeholder-reward.png
│   ├── icons/
│   │   ├── favicon.ico
│   │   ├── apple-touch-icon.png
│   │   └── android-chrome.png
│   ├── fonts/
│   │   ├── inter-regular.woff2
│   │   └── inter-bold.woff2
│   └── animations/
│       └── lottie-animations.json
│
├── 📂 services/                         # Serviços Compartilhados
│   ├── supabase-client.js               # Inicialização Supabase
│   ├── auth-service.js                  # Gerenciamento de Auth
│   ├── api-service.js                   # Camada de API
│   ├── storage-service.js               # Upload/Download de Arquivos
│   ├── notifications-service.js         # Notificações em Tempo Real
│   └── validation.js                    # Validações de Dados
│
├── 📚 docs/                             # Documentação
│   ├── README.md                        # Visão Geral
│   ├── SETUP.md                         # Guia de Instalação
│   ├── ARCHITECTURE.md                  # Arquitetura do Projeto
│   ├── API.md                           # Documentação da API
│   ├── DATABASE.md                      # Schema do Banco
│   ├── DEPLOYMENT.md                    # Deploy em Produção
│   ├── SUPABASE-CONFIG.md               # Configuração Supabase
│   ├── SECURITY.md                      # Boas Práticas de Segurança
│   └── TESTING.md                       # Testes
│
├── 🧪 tests/                            # Testes Automatizados
│   ├── __tests__/
│   │   ├── auth.test.js
│   │   ├── api.test.js
│   │   └── utils.test.js
│   ├── e2e/
│   │   ├── login.e2e.js
│   │   ├── purchase-upload.e2e.js
│   │   └── admin-approval.e2e.js
│   └── jest.config.js
│
├── 🔧 config/                           # Configurações
│   ├── supabase.config.js               # Configuração Supabase
│   ├── api.config.js                    # Endpoints da API
│   ├── constants.js                     # Constantes Globais
│   ├── feature-flags.js                 # Flags de Features
│   └── permissions.js                   # Matriz de Permissões
│
├── 📂 database/                         # Scripts de Banco
│   ├── supabase-schema.sql              # Schema completo
│   ├── seed.sql                         # Dados iniciais
│   ├── migrations/
│   │   ├── 001_initial-schema.sql
│   │   ├── 002_add-rls-policies.sql
│   │   └── 003_add-triggers.sql
│   └── backups/
│       └── .gitkeep
│
├── 📄 .env.example                      # Variáveis de Exemplo
├── 📄 .env.production                   # Prod (não commitar)
├── 📄 .gitignore                        # Git ignore
├── 📄 package.json                      # Dependências (se usar Node)
├── 📄 .github/
│   ├── workflows/
│   │   ├── deploy.yml                   # CI/CD Deploy
│   │   └── tests.yml                    # Testes Automáticos
│   └── ISSUE_TEMPLATE/
│       └── bug_report.md
│
├── 📄 vercel.json                       # Deploy Vercel
├── 📄 netlify.toml                      # Deploy Netlify
├── 📄 docker-compose.yml                # Docker para Dev Local
├── 📄 Dockerfile                        # Container de Produção
└── 📄 README.md                         # Documentação Principal

=== DESCRIÇÃO DAS PASTAS ===

📱 CLIENTE/
└─ Portal do Consumidor (app.sueco.com/cliente)
   ✅ Login & Registro via Supabase Auth
   ✅ Visualizar Saldo e Histórico de Pontos
   ✅ Upload de Cupom com Câmera
   ✅ QR Code Virtual
   ✅ Recompensas e Resgates
   ✅ Notificações em Tempo Real

📊 ADMIN/
└─ Painel Administrativo (app.sueco.com/admin)
   ✅ Dashboard com Estatísticas
   ✅ Aprovação de Compras
   ✅ Gestão de Clientes
   ✅ Campanhas e Cupons
   ✅ Relatórios Analíticos
   ✅ Controle de Usuários

🎨 ASSETS/
└─ Recursos Estáticos
   ✅ Logos e Imagens
   ✅ Ícones e Favicons
   ✅ Fontes Otimizadas
   ✅ Animações Lottie

📂 SERVICES/
└─ Camada de Serviços
   ✅ Cliente Supabase Inicializado
   ✅ Autenticação
   ✅ Requisições API
   ✅ Upload de Arquivos
   ✅ Sync em Tempo Real

📚 DOCS/
└─ Documentação Completa
   ✅ Setup e Instalação
   ✅ Arquitetura
   ✅ API Reference
   ✅ Deploy

🧪 TESTS/
└─ Testes Automatizados
   ✅ Unit Tests
   ✅ E2E Tests
   ✅ Jest Config

🔧 CONFIG/
└─ Configurações Globais
   ✅ Supabase
   ✅ API Endpoints
   ✅ Constantes
   ✅ Feature Flags

📂 DATABASE/
└─ Scripts SQL
   ✅ Schema Completo
   ✅ Seeds
   ✅ Migrations Versionadas
