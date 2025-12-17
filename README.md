# EfootRound ⚽

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

##  Visão Geral do Projeto

Aplicativo desenvolvido como projeto final da disciplina **MATC89 - Aplicações para Dispositivos Móveis** da UFBA.

O **EfootRound** é um gerenciador de campeonatos de futebol que automatiza o controle de partidas, times e classificações, facilitando a organização de torneios entre amigos.

##  Motivação

Durante campeonatos de futebol mobile entre amigos, identificamos que armazenar resultados e gerar classificações manualmente era trabalhoso e sujeito a erros. 

Assim surgiu o **EfootRound**: uma solução que permite criar campeonatos, adicionar times, gerenciar rodadas e obter classificações automaticamente. O app também é útil para organizar "rachas" ou "peladas" - como são conhecidos os jogos entre amigos.

##  Funcionalidades

-  **Gestão de Campeonatos**: Criar, editar e excluir campeonatos
-  **Gerenciamento de Times**: CRUD completo de times vinculados aos campeonatos
-  **Controle de Rodadas**: Criar rodadas e registrar jogos
-  **Registro de Resultados**: Adicionar placares das partidas
-  **Classificação Automática**: Tabela atualizada em tempo real com:
  - Pontos (vitória = 3pts, empate = 1pt)
  - Jogos, vitórias, empates e derrotas
  - Saldo de gols
  - Ordenação automática (pontos → saldo → gols pró)
-  **Compartilhamento**: Download da classificação como imagem (PNG)
-  **Interface Responsiva**: Design adaptado para diferentes tamanhos de tela

##  Arquitetura

O projeto segue a **arquitetura em camadas** apresentada em aula:

```
lib/
├── models/           # Modelos de dados (Championship, Team, Game, Round)
├── repositories/     # Acesso ao banco de dados (Supabase)
├── controllers/      # Lógica de negócio e gerenciamento de estado
└── widgets/          # Interface do usuário (Screens e Components)
```

### Padrões Utilizados

- **Riverpod 2.5+** com geração de código para gerenciamento de estado global
- **Hooks** para estados locais e ciclo de vida
- **Repository Pattern** para abstração do acesso aos dados
- **MVC adaptado** (Model-View-Controller)

##  Tecnologias

| Tecnologia        | Versão | Uso                                          |
| ----------------- | ------ | -------------------------------------------- |
| **Flutter**       | 3.x    | Framework de desenvolvimento                 |
| **Dart**          | 3.x    | Linguagem de programação                     |
| **Riverpod**      | 3.0.3  | Gerenciamento de estado                      |
| **Supabase**      | 2.10.3 | Backend e banco de dados PostgreSQL          |
| **Flutter Hooks** | 0.21.3 | Hooks para gerenciamento de estado local     |
| **package:web**   | 1.1.0  | Interoperabilidade Web (download de imagens) |

##  Banco de Dados

### Modelo Relacional (1:N)

```
championships (1) ──── (N) teams
      │
      └──────────────── (N) rounds
                              │
                              └──── (N) games
```

### Tabelas no Supabase

**championships**
- `id` (PK)
- `name`
- `created_at`

**teams** (1:N com championships)
- `id` (PK)
- `name`
- `championship_id` (FK)

**rounds** (1:N com championships)
- `id` (PK)
- `round_number`
- `championship_id` (FK)

**games** (N:1 com rounds)
- `id` (PK)
- `round_id` (FK)
- `championship_id` (FK)
- `time_a_id` (FK → teams)
- `time_b_id` (FK → teams)
- `gols_time_A`
- `gols_time_B`

##  Recursos Extras Implementados

###  Download de Classificação como Imagem

Implementado usando **`package:web`** e **`dart:js_interop`** (padrão moderno do Flutter Web):

```dart
// Captura a tabela como imagem
final RenderRepaintBoundary boundary = ...;
final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

// Converte para PNG
final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
final Uint8List pngBytes = byteData.buffer.asUint8List();

// Download via Web API
final blob = web.Blob([pngBytes.toJS].toJS);
final url = web.URL.createObjectURL(blob);
final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
anchor.href = url;
anchor.download = 'classificacao.png';
anchor.click();
```

**Funcionalidades:**
- Captura de screenshot da classificação
- Preserva cores e formatação (top 3 destacados)
- Download automático no navegador
- Alta resolução (pixelRatio: 3.0)

## Como Executar

### Pré-requisitos

- Flutter SDK 3.x ou superior
- Conta no Supabase
- Navegador web (Chrome recomendado)

### Configuração

1. Clone o repositório:
```bash
git clone <url-do-repositorio>
cd myapp
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure o Supabase:
   - Crie um projeto no [Supabase](https://supabase.com)
   - Execute os scripts SQL para criar as tabelas (ver `/supabase/schema.sql`)
   - Configure as credenciais em `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'SUA_URL_AQUI',
  anonKey: 'SUA_CHAVE_AQUI',
);
```

4. Execute o app:
```bash
# versao apenas web
flutter run -d chrome
```

## 📸 Screenshots

### Tela Inicial
![Home Screen](screenshots/home.png)

### Gerenciamento de Times
![Teams Screen](screenshots/teams.png)

### Classificação
![Standings Screen](screenshots/standings.png)

### Rodadas
![Rounds Screen](screenshots/rounds.png)

##  Requisitos Atendidos

- [x] **2 CRUDs com relação 1:N**
  - Championships → Teams (1:N)
  - Championships → Rounds (1:N)
  - Rounds → Games (1:N)
  - Teams participam de Games (N:M)

- [x] **Riverpod 2.5+ com gerador de código**
  - `@riverpod` annotations
  - Providers gerados automaticamente
  - Estado global gerenciado

- [x] **Arquitetura em camadas**
  - Widgets (UI)
  - Controllers (Lógica)
  - Repositories (Dados)
  - Models (Entidades)

- [x] **Persistência na nuvem**
  - Supabase (PostgreSQL)
  - Queries em tempo real
  - Relações entre tabelas

- [x] **Recurso extra**
  - Download de classificação como imagem
  - Uso de `package:web` e `dart:js_interop`
  - Integração com APIs Web modernas

## Testes

```bash
flutter analyze

```

## 👥 Autor

**Thiago** - Estudante de Ciência da Computação - UFBA

## Licença

Este projeto foi desenvolvido para fins acadêmicos na disciplina MATC89.

⚽ **EfootRound** - Organize seus campeonatos com facilidade!