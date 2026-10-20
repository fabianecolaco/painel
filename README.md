# Painel Teacher Fabi

Painel completo da professora Fabiane Colaço: agenda, alunos, financeiro (com a imagem da mensalidade e QR Pix), atividades, correções, documentos da marca e ajustes.
E a **página do aluno**: cada aluno entra pelo link dele + PIN de 4 números, faz as atividades, vê notas, aulas e mensalidade, personaliza a página e marca reposição (só com 48h de antecedência).

- **Site:** HTML/CSS/JS puros, sem build. Hospedado no **GitHub Pages**.
- **Dados:** **Supabase** (gratuito). Login com **e-mail e senha**, e só a conta da Fabi entra.
- Com o `config.js` vazio, o site abre em **modo demonstração**, com alunos de exemplo salvos só no navegador.

## Arquivos

| Arquivo | O que é |
|---|---|
| `index.html` | O painel |
| `config.js` | **Onde vão a URL e a chave do Supabase** |
| `docs/` | Arquivos da marca (aba Documentos) |
| `supabase/schema.sql` | Cria a tabela e as regras de segurança |
| `supabase/portal.sql` | Funções seguras da página do aluno (PIN) |
| `aluno/index.html` | A página do aluno |
| `favicon.svg` | Ícone da aba do navegador |
| `manifest.webmanifest`, `aluno/manifest.webmanifest`, `sw.js`, `icons/` | Deixam o painel e a página do aluno instaláveis como app |

---

## Passo 1 · Supabase (uns 10 minutos)

1. Entre em **supabase.com** com a conta da Fabiane e clique em **New project**.
   - Nome: `painel-fabi`
   - Senha do banco: gere uma e guarde (não é a senha do painel)
   - Região: **South America (São Paulo)**
2. **Criar a tabela:** menu da esquerda, **SQL Editor → New query**. Cole todo o conteúdo de `supabase/schema.sql` e clique em **Run**. Deve aparecer *Success*.
3. **Criar o acesso da Fabi:** **Authentication → Users → Add user → Create new user**.
   - E-mail: o e-mail dela
   - Senha: uma senha provisória (ela troca depois dentro do painel)
   - Marque **Auto Confirm User** e clique em **Create user**.
4. **Fechar o cadastro para mais ninguém:** **Authentication → Sign In / Providers → Email** e **desative "Allow new users to sign up"**. Salve.
5. **Copiar as chaves:** **Project Settings → API** (ou **Data API / API Keys**). Copie:
   - **Project URL**, algo como `https://abcd1234.supabase.co`
   - a chave **anon public**, que começa com `eyJ…`, ou a **Publishable key**, que começa com `sb_publishable_…`
6. Cole as duas no `config.js`:
   ```js
   window.APP_CONFIG = {
     SUPABASE_URL: "https://abcd1234.supabase.co",
     SUPABASE_ANON_KEY: "eyJ...."
   };
   ```
   A chave anon/publishable pode ficar no GitHub: ela é pública por natureza, e quem protege os dados são as regras do `schema.sql`. **Nunca** use a chave `service_role` / secret.

## Passo 2 · GitHub (código e hospedagem)

1. No GitHub da Fabi: **+ → New repository**.
   - Nome: `painel`
   - Marque **Public** (o GitHub Pages gratuito exige). Os dados ficam no Supabase, protegidos pelo login; o código não tem nada pessoal.
   - Clique em **Create repository**.
2. Clique em **uploading an existing file** e arraste **o conteúdo** desta pasta: `index.html`, `config.js`, `favicon.svg`, `README.md` e as pastas `docs` e `supabase`. O `index.html` precisa ficar na **raiz**, e não dentro de outra pasta.
3. Clique em **Commit changes**.

## Passo 3 · Publicar o link

1. No repositório, **Settings → Pages**.
2. Em *Build and deployment*: **Source: Deploy from a branch**, **Branch: main**, pasta **/ (root)**, e clique em **Save**.
3. Em 1 ou 2 minutos aparece no topo: *"Your site is live at …"*.
   O link do painel fica assim: **`https://USUARIO-DA-FABI.github.io/painel/`**

## Passo 4 · Primeiro acesso da Fabi

1. Ela abre o link e entra com o e-mail e a senha provisória.
2. Em **Ajustes → Trocar senha**, ela cria a senha dela.
3. Em **Ajustes → Pix e card da mensalidade**, cadastra a chave Pix.
4. Em **Ajustes → Disponibilidade padrão**, confere os horários.
5. Em **Alunos → + Novo aluno**, cadastra a turma.

> Esqueceu a senha? No Supabase, em **Authentication → Users**, clique nos três pontinhos do usuário e defina uma nova senha.

## Bom saber

- **Salvamento automático:** tudo vai para o Supabase sozinho. O topo mostra *Salvando… / Tudo salvo*.
- **Dois aparelhos ao mesmo tempo:** se ela mexer no celular e no computador juntos, o painel carrega o que foi salvo por último e avisa. Vale fechar a aba de um antes de usar o outro.
- **Atualizar o site:** qualquer arquivo novo no GitHub publica sozinho em 1 ou 2 minutos. Os dados não se perdem.
- **Idioma e tema:** PT/EN e claro/escuro ficam no topo, e o painel lembra a escolha em cada aparelho.

---

## Página do aluno (atualização)

1. **Supabase → SQL Editor → New query:** cole todo o `supabase/portal.sql` e clique em **Run**. Deve aparecer *Success*. (Pode rodar de novo sem problema.)
2. **GitHub:** suba o `index.html` novo e a pasta **`aluno`** (com o `index.html` dela dentro).
3. Pronto. O link de cada aluno fica `https://fabianecolaco.github.io/painel/aluno/#final-do-link` e o PIN aparece no perfil do aluno no painel.

Como funciona:
- O aluno digita o PIN uma vez; o aparelho dele lembra. 8 PINs errados em 15 min bloqueiam aquele link por 15 min.
- O aluno **nunca** vê observação privada, telefones, anotações do diário ou dados de outros alunos.
- O que o aluno faz (respostas, cor/foto da página, reposição) chega no painel sozinho (ao abrir, ao voltar para a aba e a cada minuto) e aparece no sino 🔔.
- **Reposição:** só para falta dos últimos 60 dias que ainda não foi reposta, só em horário livre da disponibilidade da Fabi (a da semana, se ela editou), sem conflito com outro aluno, com pelo menos 48h de antecedência e até 2 semanas à frente. Se ela não puder, basta apagar a reposição na agenda.
- Mudou o PIN no painel? O aluno precisa digitar o novo na próxima vez.

---

## Atualização · avisos, WhatsApp, conquistas, explicação e app

1. **Supabase → SQL Editor:** rode de novo o `supabase/portal.sql` inteiro (agora ele também envia os avisos para o aluno).
2. **GitHub:** suba tudo de novo: `index.html`, `manifest.webmanifest`, `sw.js`, as pastas `aluno` e `icons`.

O que tem de novo:
- **📣 Avisos:** em Alunos (para todos) ou no perfil (só para um aluno). Aparece no topo da página do aluno até a data escolhida.
- **💬 WhatsApp:** no perfil, em Atividades → Em andamento, nos alunos em alerta e em cada mensalidade. Abre o WhatsApp com a mensagem pronta (atividades, link e PIN, próxima aula ou mensalidade).
- **Conquistas:** 8 selos na página do aluno (aparecem também no perfil, para a Fabi).
- **Explicação:** nas questões de marcar X e verdadeiro/falso, um campo "Explicação" que o aluno vê quando erra. No Word, escreva numa linha logo depois das opções: `Explicação: ...`.
- **📲 Instalar app:** botão no topo do painel e da página do aluno. No iPhone: Safari → Compartilhar → Adicionar à Tela de Início. No Android e no computador (Chrome/Edge): o botão já instala.

---

## Atualização · saldo de reposição

1. **Supabase → SQL Editor:** rode de novo o `supabase/portal.sql` inteiro (a regra de reposição agora usa o saldo).
2. **GitHub:** suba o `index.html` e a pasta `aluno` novos.

Como funciona:
- **Saldo** = ajuste manual + faltas − reposições. Não vence.
- **Ajuste do saldo** (no perfil do aluno, em Reposições): para lançar aulas antigas de uma vez (ex.: 8). Número negativo tira.
- **Aluno:** pede quantas reposições quiser enquanto tiver saldo, sempre em horário livre e com 48h de antecedência, e diz qual aula faltada cada uma repõe (uma falta da lista, "aula antiga" ou outra data).
- **Fabi aceita:** o pedido reserva o horário e aparece no topo da Agenda (aba "Agenda ⏳") e no perfil do aluno. ✓ Aceitar confirma; ✕ Recusar libera o horário e devolve o crédito. Reposições que a própria Fabi marca (lote, avulsa ou no modo aula) já entram confirmadas.
- **Trocar a falta de referência:** toque na reposição na Agenda e escolha "Qual aula faltada esta reposição repõe".
- **Fabi em lote:** "Marcar reposições em lote" escolhe dia e horário fixo e agenda uma por semana, pulando conflitos.
- **Falta na reposição:** na Agenda, toque na reposição e escolha "Faltou · devolver crédito" ou "Faltou · perder crédito".
- **Como saber o que foi:** na Agenda aparece "reposição de 05/10"; no calendário, ↺ antes do horário; no perfil, o histórico mostra cada falta e cada reposição, quem marcou e se foi feita.
