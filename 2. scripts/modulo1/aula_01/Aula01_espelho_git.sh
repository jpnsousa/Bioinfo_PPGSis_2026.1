# =============================================================================
#  ESPELHO — Ciclo completo de Git para digitar junto em aula
#  CHS0007 · Bioinformática · PPGSIS/UFC
#
#  Como usar: digite UMA linha por vez no terminal do Codespace e observe o
#  resultado antes de seguir. Os alunos digitam junto. (Não rode tudo de uma vez.)
# =============================================================================


# --- 0. Quem sou eu?  (só na primeira vez no Codespace) ----------------------
git config --global user.name  "Seu Nome"
git config --global user.email "voce@ufc.br"


# --- 1. Onde estou e como está o repositório? --------------------------------
pwd                 # em que pasta estou?
git status          # o comando que você mais vai usar: o que mudou?


# --- 2. Criar um arquivo  (working directory = sua área de trabalho) ---------
echo "# Notas - Aula 1 Bioinformática" >  notas_aula1.md
echo "Data: 15/06/2026"                >> notas_aula1.md
cat notas_aula1.md                      # conferir o conteúdo

git status          # arquivo NOVO aparece em VERMELHO (não rastreado)


# --- 3. Selecionar para o commit  (git add → staging area) -------------------
git add notas_aula1.md

git status          # agora aparece em VERDE (na fila do próximo commit)


# --- 4. Registrar o snapshot  (git commit) -----------------------------------
git commit -m "Adiciona notas da primeira aula"

git log --oneline   # histórico: uma linha por commit


# --- 5. Modificar o arquivo e ver a diferença --------------------------------
echo "Organismo de estudo: Bradyrhizobium" >> notas_aula1.md

git status          # agora diz "modified" (modificado, ainda não selecionado)
git diff            # mostra EXATAMENTE o que mudou (+ adicionado / - removido)


# --- 6. Versionar a modificação  (fecha o ciclo: add + commit) ---------------
git add notas_aula1.md
git commit -m "Acrescenta organismo de estudo"

git log --oneline   # agora dois commits, um único arquivo


# --- 7. Enviar para o GitHub  (git push) -------------------------------------
git push origin main   # publica seus commits no repositório remoto


# --- 8. Receber mudanças do remoto  (git pull — útil em equipe) --------------
git pull origin main   # baixa atualizações que estejam no GitHub


# =============================================================================
#  RESUMO DO CICLO
#    working directory → git add → staging → git commit → git push
#
#  Os 4 do dia a dia:  git status · git add · git commit -m · git push origin main
# =============================================================================
