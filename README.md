# 💣 Two Chambers and a Kaboom

Um jogo de dedução social para dispositivos móveis, desenvolvido em Ruby on Rails 8 com Turbo e Hotwire.

![Ruby](https://img.shields.io/badge/Ruby-3.2+-red?logo=ruby)
![Rails](https://img.shields.io/badge/Rails-8.0-red?logo=rubyonrails)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4-blue?logo=tailwindcss)

---

## 🎮 Sobre o Jogo

**Two Chambers and a Kaboom** é um jogo de festa onde os jogadores são divididos em dois times (Azul e Vermelho) e separados em duas salas. O objetivo varia de acordo com o time:

- 🔵 **Time Azul:** Manter o Presidente longe do Bombardeiro
- 🔴 **Time Vermelho:** Fazer o Bombardeiro ficar na mesma sala que o Presidente

Durante o jogo, os jogadores negociam e trocam reféns entre as salas, tentando descobrir quem é quem e manipular a situação a favor do seu time.

---

## ✨ Funcionalidades

- 📱 **Interface Mobile-First** - Otimizado para smartphones
- 🔄 **Tempo Real** - Atualizações instantâneas com Turbo Streams
- 👥 **Multiplayer** - Suporta múltiplos jogadores por sala
- 🎭 **Papéis Secretos** - Presidente, Bombardeiro e membros regulares
- ⏱️ **Cronômetro Configurável** - Defina o tempo de cada rodada
- 👑 **Votação de Líder** - Sistema democrático com desempate automático
- 🔄 **Troca de Reféns** - Baseada nas regras oficiais do jogo
- 🔐 **Sistema de PIN** - Acesso simples com PIN de 3 dígitos
- 🛠️ **Painel Admin** - Gerenciamento de salas e jogadores

---

## 🚀 Instalação

### Pré-requisitos

- Ruby 3.2+
- Rails 8.0+
- SQLite3
- Node.js 18+

### Passos

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/two-rooms-and-a-boom.git
cd two-rooms-and-a-boom

# Instale as dependências
bundle install

# Configure o banco de dados
rails db:create db:migrate

# Inicie o servidor
bin/dev
```

Acesse `http://localhost:3000` no seu navegador.

---

## 🎯 Como Jogar

### Criando uma Sala

1. Acesse a página inicial
2. Digite seu nome
3. Crie um PIN de 3 dígitos
4. Clique em **"Criar Nova Sala"**
5. Compartilhe o código da sala com os outros jogadores

### Entrando em uma Sala

1. Acesse a página inicial
2. Digite seu nome e PIN
3. Clique em **"Entrar em uma Sala"**
4. Digite o código da sala

### Durante o Jogo

1. **Fase de Conversa:** Discuta com os jogadores da sua sala
2. **Votação de Líder:** Vote em quem será o líder da rodada
3. **Troca de Reféns:** O líder escolhe quem vai para a outra sala
4. **Repetir:** Continue até a última rodada
5. **Revelação:** Descubra se o Presidente e o Bombardeiro estão na mesma sala!

---

## 🛠️ Painel Admin

Acesse as ferramentas de administração:

- `/admin/reset-pin` - Resetar PIN de jogadores
- `/admin/reset-room` - Apagar salas
- `/admin/reset-player` - Remover jogadores

---

## 📋 Regras Oficiais

### Quantidade de Rodadas por Número de Jogadores

| Jogadores | Rodadas |
|-----------|---------|
| 6-10      | 3       |
| 11-21     | 3       |
| 22+       | 3       |

### Quantidade de Reféns por Rodada

| Rodada | Reféns Trocados |
|--------|-----------------|
| 1      | Muitos          |
| 2      | Alguns          |
| 3      | 1               |

---

## 🏗️ Tecnologias

- **Backend:** Ruby on Rails 8
- **Frontend:** Hotwire (Turbo + Stimulus)
- **Estilização:** Tailwind CSS
- **Banco de Dados:** SQLite3
- **Real-time:** Action Cable + Turbo Streams

---

## 📁 Estrutura do Projeto

```
app/
├── controllers/
│   ├── games_controller.rb    # Lógica do jogo
│   ├── players_controller.rb  # Gerenciamento de jogadores
│   ├── admin_controller.rb    # Funções administrativas
│   └── home_controller.rb     # Página inicial
├── models/
│   ├── game.rb               # Modelo do jogo
│   └── player.rb             # Modelo do jogador
├── views/
│   ├── games/                # Views do jogo
│   ├── home/                 # Página inicial
│   └── shared/               # Componentes compartilhados
└── javascript/
    └── controllers/          # Stimulus controllers
```

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues e pull requests.

---

## 📄 Licença

Este projeto é apenas para fins educacionais e de entretenimento. Two Chambers and a Kaboom é um jogo criado pela Tuesday Knight Games.

---

## 🙏 Créditos

- **Jogo Original:** [Tuesday Knight Games](https://www.tuesdayknightgames.com/)
- **Desenvolvimento:** Feito com ❤️ usando Ruby on Rails

---

<p align="center">
  <strong>Divirta-se! 🎉</strong>
</p>
