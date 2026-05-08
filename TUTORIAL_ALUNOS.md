# 🧬 Guia de configuração do ambiente — Bioinformática PPGSIS 2026

**Dr. Yan Torres · Universidade Federal do Ceará**

Este guia explica como configurar o seu ambiente de trabalho para a disciplina.
Você vai usar o **GitHub Codespaces** — um computador Linux completo que roda no navegador, sem precisar instalar nada no seu PC.

> ⏱ **Tempo estimado:** 25–35 minutos na primeira vez (a maior parte é espera automática).

---

## Pré-requisitos

- [ ] Conta no GitHub (gratuita) — [criar em github.com](https://github.com)
- [ ] Navegador atualizado (Chrome, Firefox ou Edge)
- [ ] Conexão à internet estável

Não precisa instalar nada além disso.

---

## Passo 1 — Criar uma conta no GitHub (se ainda não tiver)

1. Acesse [github.com](https://github.com) e clique em **Sign up**
2. Use seu e-mail institucional (`.ufc.br`) — isso facilita acesso a benefícios educacionais
3. Escolha o plano **Free**
4. Confirme o e-mail recebido

> 💡 Se já tiver conta, pule para o Passo 2.

---

## Passo 2 — Fazer fork do repositório da disciplina

O **fork** cria uma cópia do repositório do professor **na sua conta**. É o seu espaço de trabalho pessoal.

1. Acesse o repositório da disciplina:
   **`https://github.com/yanttp/Bioinfo_PPGSis_2026.1`**

2. Clique no botão **Fork** (canto superior direito)

   ```
   ┌─────────────────────────────────────┐
   │  yanttp / Bioinfo_PPGSis_2026.1     │
   │                          [Fork ▾]   │
   └─────────────────────────────────────┘
   ```

3. Na tela que aparecer:
   - **Owner:** selecione **sua conta** (não a do yanttp)
   - **Repository name:** pode deixar o mesmo nome
   - Clique em **Create fork**

4. Aguarde alguns segundos. Você será redirecionado para:
   **`https://github.com/SEU_USUARIO/Bioinfo_PPGSis_2026.1`**

✅ **Pronto — você tem sua cópia pessoal do repositório.**

---

## Passo 3 — Criar o Codespace

O Codespace é o ambiente onde você vai trabalhar. Como ele já é criado **no seu fork**, o custo sai da sua cota gratuita (não do professor).

1. No seu fork (página `github.com/SEU_USUARIO/Bioinfo_PPGSis_2026.1`), clique no botão verde **`<> Code`**

2. Clique na aba **Codespaces**

3. Clique em **`... → New with options`** (não clique no botão simples ainda)

   ```
   ┌─────────────────────────────┐
   │  Codespaces                 │
   │  ┌─────────────────────┐    │
   │  │ + New codespace  ▾  │    │
   │  └─────────────────────┘    │
   │    → New with options       │
   └─────────────────────────────┘
   ```

4. Configure assim:
   | Campo | Valor |
   |-------|-------|
   | Branch | `main` |
   | Region | `US East` (ou mais próximo) |
   | **Machine type** | **`2-core · 8 GB RAM · 32 GB`** ⚠️ |

   > ⚠️ **Use 2-core, não 4-core.** A máquina 2-core usa 2 core-hours/hora e mantém você dentro da cota gratuita de 120 core-hours/mês. Para os datasets desta disciplina, 2 cores são suficientes.

5. Clique em **Create codespace**

---

## Passo 4 — Aguardar a configuração automática

Após criar, o Codespace vai:

1. Abrir o **VSCode no navegador** (pode levar 1–2 min)
2. Rodar automaticamente o script de configuração em segundo plano
3. Instalar todos os softwares da disciplina (~15–20 min)

Você verá uma notificação no canto inferior direito:

```
⚙ Running postCreateCommand...
```

**Não feche a aba.** Você pode acompanhar o progresso clicando em **"Show log"**.

> ☕ Boa hora para um café — é só aguardar.

---

## Passo 5 — Verificar se tudo instalou corretamente

Quando a notificação desaparecer, abra um **terminal** no VSCode:

- Menu: **Terminal → New Terminal**
- Ou pressione: `` Ctrl + ` ``

Execute o script de verificação:

```bash
conda activate bioinfo
bash .devcontainer/verificar.sh
```

Você verá algo assim:

```
═══════════════════════════════════════════════
  Verificação do ambiente — Bioinformática 2026
═══════════════════════════════════════════════

── Módulo 1/2: Utilitários e QC ───────────────
  ✔ seqkit — seqkit v2.8.2
  ✔ FastQC — FastQC v0.12.1
  ✔ MultiQC — multiqc, version 1.22
  ✔ fastp — fastp 0.23.4
  ...

  Resultado: 28 OK / 0 falhas
  ✅ Tudo pronto! Pode começar.
```

Se aparecer algum `✘`, avise o professor no canal da disciplina.

---

## Passo 6 — Acessar o RStudio Server (para análises em R)

O RStudio está disponível pelo navegador dentro do Codespace:

1. Clique na aba **PORTS** na barra inferior do VSCode
2. Procure a linha com a porta **8787** (label: "RStudio Server")
3. Clique no ícone de globo 🌐 para abrir no navegador
4. Login: `vscode` / Senha: `vscode`

> Alternativamente, você pode usar R diretamente no terminal com `Rscript` ou pelo editor do VSCode com a extensão R já instalada.

---

## Passo 7 — Estrutura de pastas do projeto

Seu repositório já vem com a seguinte estrutura:

```
Bioinfo_PPGSis_2026.1/
├── dados/
│   ├── brutos/       ← dados originais (nunca modificar!)
│   ├── limpos/       ← após QC e trimagem
│   └── resultados/   ← outputs das análises
├── scripts/
│   ├── modulo1/
│   ├── modulo2/
│   ├── modulo3/
│   ├── modulo4/
│   └── modulo5/
├── projetos/
│   └── grupo/        ← trabalho do seu grupo aqui
├── figuras/
├── relatorio/
└── .devcontainer/    ← configuração do ambiente (não modificar)
```

---

## Git: fluxo de trabalho básico

Você vai usar Git para salvar e compartilhar seu trabalho. Os três comandos essenciais:

```bash
# 1. Verificar o que mudou
git status

# 2. Adicionar arquivos ao próximo commit
git add scripts/modulo2/pipeline_qc.sh
# ou adicionar tudo de uma vez:
git add .

# 3. Salvar com uma mensagem descritiva
git commit -m "Adiciona pipeline de QC do Módulo 2"

# 4. Enviar para o GitHub
git push
```

### Entregando o projeto final

Quando o trabalho do grupo estiver pronto:

1. Faça o commit e push de tudo no seu fork
2. Acesse seu fork no GitHub
3. Clique em **"Contribute" → "Open pull request"**
4. Título: `[Projeto Final] NomesDoGrupo — Tema escolhido`
5. Clique em **"Create pull request"**

O professor receberá a notificação e vai avaliar pelo Pull Request.

---

## Gerenciando sua cota de Codespaces

Você tem **120 core-hours/mês gratuitos** (máquina 2-core = 2 core-hours/hora).

| Situação | Core-hours/hora |
|----------|----------------|
| Máquina 2-core | 2 |
| Máquina 4-core | 4 |

Isso dá **60 horas** de uso na máquina 2-core — suficiente para toda a disciplina.

**⚠️ Hábito importante:** pare o Codespace quando não estiver usando!

```
GitHub → Seu fork → <> Code → Codespaces → Stop codespace
```

O Codespace para automaticamente após **30 minutos de inatividade**, mas parar manualmente garante que não consuma cota em segundo plano.

Para retomar de onde parou:

```
GitHub → Seu fork → <> Code → Codespaces → [nome do seu codespace]
```

Seus arquivos ficam salvos mesmo com o Codespace parado.

---

## Ambientes conda disponíveis

| Ambiente | Ativar com | Usado em |
|----------|-----------|----------|
| `bioinfo` | `conda activate bioinfo` | Módulos 1, 2, 3, 5 (padrão) |
| `qiime2-amplicon` | `conda activate qiime2-amplicon` | Módulo 4 (Metagenômica) |

Para voltar ao ambiente principal:
```bash
conda activate bioinfo
```

---

## Problemas frequentes

**"O Codespace trava na configuração"**
→ Aguarde — a instalação do QIIME2 pode levar até 20 min. Se travar por mais de 30 min, avise o professor.

**"Não consigo ver a porta 8787 do RStudio"**
→ No terminal: `sudo rstudio-server restart` e aguarde 30 segundos.

**"Git push pede senha"**
→ No terminal: `gh auth login` e siga as instruções (autenticação pelo GitHub CLI já vem instalado).

**"Comando não encontrado (command not found)"**
→ Verifique se o ambiente está ativo: `conda activate bioinfo`

**"Perdi meus arquivos"**
→ Se fez `git push`, estão no GitHub. Se não fez push, verifique se o Codespace ainda existe em `github.com → Codespaces`.

---

## Suporte

- 📧 E-mail do professor: yantorres@ufc.br
- 💬 Canal da turma: Github Discussions
- 📖 Documentação do Codespaces: [docs.github.com/codespaces](https://docs.github.com/pt/codespaces)
- 🔬 Repositório da disciplina: `github.com/yanttp/Bioinfo_PPGSis_2026.1`

---

*Bioinformática PPGSIS/UFC · 2026/1 · Dr. Yan Torres*
