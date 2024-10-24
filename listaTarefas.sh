#!/usr/bin/env bash

# listaTarefas - Gerencia uma lista de tarefas com interface grafica.

# Autor:       Guilherme Campos

# Manutenção:  Guilherme Campos

# ------------------------------------------------------------------------ #

#  sintaxe do banco de dados
#  	- 1:Nome_Da_Atividade:Status
# ------------------------------------------------------------------------ #

# Histórico:

#   v1.0 16/10/2024, Guilherme Campos:

#       - Início do programa

#   v1.1 23/10/2024. Guilherme Campos:
#   	- Adicionando persistencia de dados
#   v1.2 23/10/2024. Guilherme Campos:
#   	- CRUD adicionado
#   v1.3 24/10/2024. Guilherme Campos:
#   	- Interface grafica adicionada
# ------------------------------------------------------------------------ #

# Testado em:

#   bash 5.2.21

# ------------------------------- VARIÁVEIS ----------------------------------------- #

SOBRE="
 Este programa gerencia tarefas e seus respectivos status, que podem ser 'pendente' ou 'concluído'. 
 Ele utiliza um arquivo de texto (.txt) como banco de dados para armazenar as informações, 
 oferecendo uma maneira simples e eficiente de organizar suas atividades."
SEP=:
ARQ_DB="tarefas.txt"
ARQ_TEMP=temp.$$

VERDE="\033[32m"
VERMELHO="\033[31m"

OPERACAO=0
#-------------------------------- TESTE -------------------------------------------- #

[ ! -e $ARQ_DB ] && echo -e "${VERMELHO}ERRO\e[0m, Arquivo não existe" && exit 1
[ ! -w $ARQ_DB ] && echo -e "${VERMELHO}ERRO\e[0m, Arquivo não tem permissão de escrita" && exit 1
[ ! -r $ARQ_DB ] && echo -e "${VERMELHO}ERRO\e[0m, Arquivo não tem permissão leitura" && exit 1
[ ! -x "$(which dialog)" ] && echo "Dialog não existe, instalando" && sudo apt install dialog

#------------------------------- FUNÇÔES -------------------------------------------- #

VerificaExistencia () { #verifica se o argumento existe no DB
	grep -i -q "$1$SEP" "$ARQ_DB"
}
# ------------------------------- EXECUÇÃO ----------------------------------------- #

while :
do
	acao=$(dialog --title "MENU" --stdout --menu "Escolha uma opção abaixo" 0 0 0\
		Inserir "Nova tarefa"\
	       	Remover "Remover tarefa"\
	       	Listar "Mostrar todas as tarefas"\
		Update "Atualizar o status de alguma tarefa"\
		Sobre  "Sobre o programa")

	[ $? -ne 0 ] && exit
	case $acao in
		Sobre)	
			dialog --msgbox "$SOBRE" 0 0
			;;
		Inserir) 

			ult_id="$(egrep -v "^#|^$" $ARQ_DB | sort | tail -1 | cut -c1)"
			prox_id=$(($ult_id+1))
		 	new_tarefa=$(dialog --title "Tarefas" --stdout --inputbox "Nova Tarefa:" 0 0)
			[ $? -ne 0 ] && continue

			VerificaExistencia "$new_tarefa" && {
				dialog --title "ERRO" --msgbox "Tarefa Existente" 0 0
				exit 1
			}

			estatus=$(dialog --stdout --menu "Escolha uma opção de status abaixo" 0 0 0\
                pendente "Tarefa Pendente"\
                concluido "Tarefa Concluida")
			[ $? -ne 0 ] && continue

			echo "$prox_id$SEP$new_tarefa$SEP$estatus" >> "$ARQ_DB"
			dialog --title "Sucesso" --msgbox "Tarefa Adicionada" 0 0
			;;
		Remover)

			all_tarefas=$(egrep "^#|^$" -v "$ARQ_DB" | sort -h | cut -d $SEP -f 1,2 | sed 's/:/ "/;s/$/"/')
			a_remover=$(eval dialog --stdout --menu \"Escolha uma tarefa para ser deletada\" 0 0 0 $all_tarefas)
			[ $? -ne 0 ] && continue

			grep -i -v "$a_remover$SEP" "$ARQ_DB" > "$ARQ_TEMP"
			mv "$ARQ_TEMP" "$ARQ_DB"
			dialog --msgbox "Tarefa Deletada" 0 0
			;;
		Listar) 
		
			egrep -v "^#|^$" "$ARQ_DB" | sort > "$ARQ_TEMP"
			dialog --textbox "$ARQ_TEMP" 0 0
			rm -f "$ARQ_TEMP"		
		 	;;
		Update) 
	
			tarefass=$(egrep "^#|^$" -v "$ARQ_DB" | sort -h | cut -d $SEP -f 2,3 | sed 's/:/ "/;s/$/"/' )
			new_status=$(eval dialog --stdout --menu \"Escolha uma tarefa para ser deletada\" 0 0 0 $tarefass)
			[ $? -ne 0 ] && continue
			if [[ "$(grep $new_status$SEP $ARQ_DB | cut -d $SEP -f 3)" = "pendente" ]]
			then
				sed -i "/$new_status$SEP/ s/pendente/concluido/" $ARQ_DB
			else
				sed -i "/$new_status$SEP/ s/concluido/pendente/" $ARQ_DB
			fi
		 	;;
	esac
done
