# Painel Teacher Fabi

Painel completo da professora Fabiane Colaço: agenda, alunos, financeiro (com a imagem da mensalidade e QR Pix), atividades, correções, documentos da marca e ajustes.

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
| `favicon.svg` | Ícone da aba do navegador |

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
