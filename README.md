# Painel Teacher Fabi

Painel completo da professora Fabiane Colaço: agenda, alunos, financeiro (com a imagem da mensalidade e QR Pix), atividades, gramática liberada por aluno, correções, documentos da marca e ajustes.
E a **página do aluno**: cada aluno entra pelo link dele + PIN de 4 números, faz as atividades, vê notas, aulas e mensalidade, personaliza a página e marca reposição (com a antecedência mínima definida em Ajustes, padrão 3 horas).

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
| `modelos/` | Modelos de Excel e Word para importar atividades |
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
- **Reposição:** só para falta dos últimos 60 dias que ainda não foi reposta, só em horário livre da disponibilidade da Fabi (a da semana, se ela editou), sem conflito com outro aluno, com a antecedência mínima de Ajustes (padrão 3 horas) e até 2 semanas à frente. Se ela não puder, basta apagar a reposição na agenda.
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
- **Aluno:** pede quantas reposições quiser enquanto tiver saldo, sempre em horário livre e com a antecedência mínima de Ajustes (padrão 3 horas), e diz qual aula faltada cada uma repõe (uma falta da lista, "aula antiga" ou outra data).
- **Fabi aceita:** o pedido reserva o horário e aparece no topo da Agenda (aba "Agenda ⏳") e no perfil do aluno. ✓ Aceitar confirma; ✕ Recusar libera o horário e devolve o crédito. Reposições que a própria Fabi marca (lote, avulsa ou no modo aula) já entram confirmadas.
- **Trocar a falta de referência:** toque na reposição na Agenda e escolha "Qual aula faltada esta reposição repõe".
- **Fabi em lote:** "Marcar reposições em lote" escolhe dia e horário fixo e agenda uma por semana, pulando conflitos.
- **Falta na reposição:** na Agenda, toque na reposição e escolha "Faltou · devolver crédito" ou "Faltou · perder crédito".
- **Como saber o que foi:** na Agenda aparece "reposição de 05/10"; no calendário, ↺ antes do horário; no perfil, o histórico mostra cada falta e cada reposição, quem marcou e se foi feita.

## Novidades (outubro/2026)

> **Depois de subir os arquivos, rode o `supabase/portal.sql` de novo** (SQL Editor → New query → cole tudo → Run). Ele libera a gramática na página do aluno e a reposição com 3 horas de antecedência. Pode rodar quantas vezes quiser; não apaga dados.

- **Salvamento mais seguro:** o painel envia uma coisa por vez, junta com o que foi salvo em outro aparelho em vez de descartar, tenta de novo sozinho quando a internet cai e guarda uma cópia no aparelho até subir. Se o app fechar antes de salvar, a cópia sobe na próxima vez que abrir.
- **Atividades · Completar:** cole uma frase ou um texto inteiro e toque nas palavras que o aluno vai preencher (ficam verdes; toque de novo para desfazer). Quando o aluno envia, a palavra certa aparece em verde e a errada riscada em vermelho, com a correta ao lado. A letra da música usa o mesmo jeito.
- **Caixas de texto maiores**, que crescem sozinhas enquanto você escreve. No celular o editor ocupa a tela toda. Se faltar algo para salvar, a mensagem aparece embaixo do botão e a questão fica destacada.
- **Gramática:** aba nova, numa página centralizada e livre: títulos, tamanho da letra, espaço entre linhas, alinhar (esquerda, centro, direita, justificado), cores da letra e marca-texto (já com as cores da agenda), listas e tabelas. Não é dividida por nível. Libere por aluno, para sempre (Gramática → Liberar, ou no perfil do aluno). O aluno vê em "Minha gramática" e escolhe o tópico.
- **Reposição:** antecedência mínima de 3 horas, ajustável em **Ajustes → Disponibilidade padrão**.
- **Mensalidade na página do aluno:** o valor fica escondido (R$ ••••); só aparece pendente ou pago. O 👁 mostra o valor.
- **Aula em dupla (em laranja na agenda):** basta cadastrar os dois alunos no mesmo dia e horário. A agenda mostra "👥 dupla com…", e ao tocar na aula aparece **Abrir aula em dupla**: no topo da aula, um botão troca entre um aluno e o outro, cada um com as próprias atividades. Cobrança, faltas e reposições continuam separadas.
- **Aba Reposições:** lista quem tem aula para repor. **+** lança uma aula para repor e pede a data da aula que ficou faltando (não precisa marcar a reposição na hora). **−** dá baixa numa reposição feita. Cada lançamento pode ser excluído, e dá para adicionar ou tirar aluno da lista. O saldo muda na agenda, no perfil e na página do aluno.
- **Aula na agenda:** só duas opções quando não teve aula, **Marcar falta** ou **Aula cancelada**, e as duas viram reposição. O botão grande **📖 Diário de aula** abre a página da aula: última aula e o que foi falado, o registro de hoje e as atividades recentes. Também tem **Abrir aula** e **Abrir perfil**.
- **Excluir aluno:** no perfil, **Editar dados → Excluir aluno** (toque duas vezes). Apaga o aluno e todo o histórico; para só pausar, desmarque "Aluno ativo".
- **Dupla num cadastro só** (ex.: "Eliton - Paulo"): marque **👥 Aula em dupla** em Editar dados e a aula fica laranja na agenda.
- **Diário de aula** também no perfil do aluno, ao lado de **Abrir aula**.
- **Perfil do aluno** com visual novo: Abrir aula e Diário em destaque, dados organizados e o link + PIN numa caixa só.

## Novidades (22/out/2026)

> Rode o `supabase/portal.sql` de novo depois de subir (reposição de meia aula e "aula perdida" na página do aluno).

- **Importar do Word:** entende o formato de texto com caixa de opções. A tabela numerada vira a caixa (o aluno escolhe numa lista em cada lacuna), o diálogo inteiro vira **uma** questão com todas as lacunas "(1) ____", o título do Word vira o título da atividade e o texto de situação/instruções fica num bloco só. Se o Word tiver um gabarito no fim ("Answer key", "Gabarito"), as respostas já entram; senão, ela escolhe a resposta certa de cada lacuna numa lista. Também dá para criar a caixa de opções à mão em qualquer "Completar".
- **Aulas cobradas por semana:** preenche sozinho com a quantidade de horários cadastrados (2 horários = 2). Se ela digitar outro número, o painel respeita.
- **Reposição de 30 min ou 1 h:** ao dar baixa (−) ela escolhe o tempo. 30 min numa aula de 1 h desconta 0,5; o saldo aparece como 1,5 e não deixa passar do saldo. Se o aluno tiver só meia aula de saldo, a página dele marca uma reposição de 30 min.
- **Não teve aula?** Duas opções: **🔁 Disponível para reposição** (entra no saldo) ou **✕ Aula perdida (sem reposição)**. Dá para trocar uma pela outra depois, tocando na aula.
- **Importar ficou mais fácil** (Atividades → 📥 Importar): arraste os arquivos ou escolha vários de uma vez (Word, Excel ou CSV).
  - **Modelo Excel** (`modelos/Modelo_Atividades.xlsx`): uma linha por questão, com o Tipo numa lista. **Cada aba vira uma atividade**, então dá para importar várias de uma vez e salvar todas na biblioteca numa pasta.
  - **Modelo Word** (`modelos/Modelo_Atividade.docx`): mostra o jeito que o painel entende. Dica: escrever a resposta entre colchetes, ex.: She [goes] to work.
  - **Copiar e colar do Word** mantém as tabelas e o negrito. Pontinhos (......) também viram lacuna, e uma caixa de palavras sem números também vira caixa de opções.
  - Atividade que ainda precisa de ajuste aparece com **⚠ Revisar** na biblioteca.

## Novidades (22/out/2026, noite)

- **Agenda em grade:** cada aula é um bloco no horário. **Arraste** para mudar o dia ou o horário e **puxe a borda de baixo** para 30 ou 60 min. Ao soltar, ela escolhe **só nesta semana** (a aula fica "remarcada", com botão para desfazer) ou **toda semana** (muda o horário fixo). O horário livre aparece sempre em verde. O botão ☰ Lista volta para o jeito antigo.
- **Horário ocupado:** ao marcar, arrastar ou cadastrar em cima de outro aluno, aparece o aviso com **👥 Dupla de alunos** ou **← Voltar e escolher outro horário**.
- **Confirmar reposição:** em cada reposição, **✓ Foi feita**, **↻ Foi remarcada** (novo dia e horário) ou faltou. As que já passaram e ainda não foram confirmadas aparecem numa caixa azul no topo da agenda.
- **Aula perdida** não entra no saldo de reposição (no painel e na página do aluno).
- **Importar do Word** reconhece os títulos do Word em português e o "Teacher's Answer Key" no formato "01. 5 — A booking".
- Aula com duração vazia ou 0 passa a valer 60 min.

