/***********************************************************************
*
* Autor: Eduardo Henrique dos Santos Cerolli
* GRR: 20190397
*
* Autor: Richard Fernando Heise Ferreira
* GRR: 20191053
*
* Data: 23/05/2024
* Instituição: Universidade Federal do Paraná
* Curso: Ciência da Computação
* Motivo: Trabalho de compiladores (CI1211)
*
***********************************************************************/

#include <stdio.h>
#include <string.h>
#include "tabela_simbolos.h"
 
void inicializa_tabela (tabela_simbolos_t *ts) {
    ts->topo = -1;
    return;
}

void insere (tabela_simbolos_t *ts, simbolo_t s, int nivel) {
    if ((ts->topo + 1) == MAX_TABELA)
        imprimeErro("Tamanho maximo da tabela de simbolos atingido.");

    simbolo_t aux = busca (*ts, s.nome);
    if (aux.tipo != -1) {
        if (aux.nivel >= nivel) {
            char erro[100];
            sprintf(erro, "Nome %s ja existe.", s.nome);
            imprimeErro(erro);
        }
    }

    ts->topo = ts->topo + 1;
    ts->itens[ts->topo] = s;

    return;
}
    
void retira (tabela_simbolos_t *ts, int n) {
    while ((ts->topo > -1) && (n > 0)) {
        ts->topo = ts->topo - 1;
        n--;
    }

    return;
}

simbolo_t busca (tabela_simbolos_t ts, char* nome) {
    char aux[TAM_TOKEN];
    strncpy(aux, nome, TAM_TOKEN);
    
    for (int i = ts.topo; i >= 0; i--) {
        if (strcmp(aux, ts.itens[i].nome) == 0)
            return ts.itens[i];
    }

    simbolo_t s;
    s.tipo = -1;
    return s;
}

void imprime (tabela_simbolos_t ts) {
    for (int i = 0; i <= ts.topo; i++) {
        switch (ts.itens[i].forma) {
            case VARIAVEL: printf ("%s VARIAVEL Tipo:%d Nivel:%d Deslocamento:%d\n", ts.itens[i].nome, ts.itens[i].tipo, ts.itens[i].nivel, ts.itens[i].deslocamento);break;
            case PARAMETRO_FORMAL: printf ("%s PARAMETRO_FORMAL Tipo:%d Nivel:%d Deslocamento:%d Passagem:%d\n", ts.itens[i].nome, ts.itens[i].tipo, ts.itens[i].nivel, ts.itens[i].deslocamento, ts.itens[i].param.passagem);break;
            case PROCEDIMENTO: printf ("%s PROCEDIMENTO Nivel:%d Rot:%s Param:%d\n", ts.itens[i].nome, ts.itens[i].nivel, ts.itens[i].sub_rot.rotulo, ts.itens[i].sub_rot.num_param);break;
            case FUNCAO: printf ("%s FUNCAO Nivel:%d Rot:%s Param:%d Tipo:%d Deslocamento:%d\n", ts.itens[i].nome, ts.itens[i].nivel, ts.itens[i].sub_rot.rotulo, ts.itens[i].sub_rot.num_param, ts.itens[i].tipo, ts.itens[i].deslocamento);break;
        }
    }

    return;
}

void insereVarTabela (tabela_simbolos_t *ts, char* token, int nivel, int deslocamento) {
    simbolo_t s;

    strncpy(s.nome, token, TAM_TOKEN);
    s.nivel = nivel;
    s.deslocamento = deslocamento;
    
    s.forma = VARIAVEL;
    insere (ts, s, nivel);
}

void insereRotinaTabela (tabela_simbolos_t *ts, char* token, char* rotulo, int nivel, int tipo_rotina) {
    sub_rotina_t rotina;
    simbolo_t s;

    strncpy(s.nome, token, TAM_TOKEN);
    strncpy(rotina.rotulo, rotulo, TAM_TOKEN);
    s.nivel = nivel;
    rotina.num_param = 0;
    s.forma = SEM_TIPO;
    
    if (tipo_rotina == PROCEDIMENTO) {
        s.forma = PROCEDIMENTO;
    }
    else {
        s.forma = FUNCAO;
    }

    s.sub_rot = rotina;
    insere (ts, s, nivel);
}

void insereParamTabela (tabela_simbolos_t *ts, char* token, int nivel, int passagem) {
    parametro_formal_t pf;
    simbolo_t s;

    strncpy(s.nome, token, TAM_TOKEN);
    s.nivel = nivel;
    pf.passagem = passagem;
    
    s.forma = PARAMETRO_FORMAL;
    s.param = pf;
    insere (ts, s, nivel);
}

void atualizaTipoVar (tabela_simbolos_t *ts, int tipo, int quant) {
    for (int i = ts->topo; quant > 0; i--) {
        ts->itens[i].tipo = tipo;
        quant--;
    }
}

void atualizaTipoParam (tabela_simbolos_t *ts, int tipo, int quant) {
    for (int i = ts->topo; quant > 0; i--) {
        ts->itens[i].tipo = tipo;
        quant--;
    }
}

void atualizaDeslocamentoParam (tabela_simbolos_t *ts, int nivel, int quant) {
    int deslocamento = -4;
    int iProc;
    iProc = ts->topo - quant;
    ts->itens[iProc].sub_rot.num_param = quant;

    for (int i = ts->topo; quant > 0; i--) {
        ts->itens[i].deslocamento = deslocamento;

        ts->itens[iProc].sub_rot.tipo_param[quant - 1] = ts->itens[i].tipo;
        ts->itens[iProc].sub_rot.passagem_param[quant - 1] = ts->itens[i].param.passagem;
        
        quant--;
        deslocamento--;
    }
}

void atualizaFunc (tabela_simbolos_t *ts, int tipo, int num_vars) {
    int iFunc = ts->topo - num_vars;
    ts->itens[iFunc].tipo = tipo;
    ts->itens[iFunc].deslocamento = -4 - num_vars;
}

int quantVariaveis (tabela_simbolos_t ts, int nivel) {
    for (int i = ts.topo; i >= 0; i--) {
        if ((ts.itens[i].forma == VARIAVEL) && (ts.itens[i].nivel == nivel))
            return ts.itens[i].deslocamento + 1;
    }

    return 0;
}

int quantSubRotinas(tabela_simbolos_t ts, int nivel) {
    int cont = 0;
    
    for (int i = ts.topo; i >= 0; i--) {
        if (ts.itens[i].nivel <= nivel)
            return cont;
        
        if (((ts.itens[i].forma == PROCEDIMENTO) || (ts.itens[i].forma == FUNCAO)) && (ts.itens[i].nivel == nivel + 1))
            cont++;
    }

    return cont;
}

simbolo_t buscaSimbolo (tabela_simbolos_t ts, char* nome) {
  simbolo_t simbolo = busca (ts, nome);
  char comando[100];

  if (simbolo.tipo == -1) {
      sprintf(comando, "Variavel %s não encontrada.", nome);
      imprimeErro (comando);
  }

  return simbolo;
}

void validaTipos (pilha_int* pilha, int tipo) {
    int v1 = desempilha_int (pilha);
    int v2 = desempilha_int (pilha);

    if ((v1 != tipo) || (v1 != v2))
        imprimeErro ("Operação invalida.");

    return;
}

void empilhaNUM(char *token, pilha_int *pilha) {
    char comando[100];

    sprintf(comando, "CRCT %s", token);
    geraCodigo(NULL, comando);
    empilha_int(INT, pilha);

    return;
}

void empilhaIDENT(char *token, int ivar, int quantFator, int tipoOP, sub_rotina_t rotina, pilha_int *pilha, tabela_simbolos_t ts) {
    char comando[100];
    simbolo_t simbolo = buscaSimbolo(ts, token);

    if (tipoOP == SUB_ROT) {
        if (ivar >= rotina.num_param)
            imprimeErro ("Quantidade de parâmetros inválido.");

        if (rotina.passagem_param[ivar] == REFERENCIA) {
            if (quantFator > 1)
                imprimeErro ("Parametro invalido, passagem de mais de um parametro por referencia.");

            if (simbolo.forma == PARAMETRO_FORMAL && simbolo.param.passagem == REFERENCIA) {
                sprintf(comando, "CRVL %d,%d", simbolo.nivel, simbolo.deslocamento);
            }
            else {
                sprintf(comando, "CREN %d,%d", simbolo.nivel, simbolo.deslocamento);
            }
        }
        else {
            if (simbolo.forma == PARAMETRO_FORMAL && simbolo.param.passagem == REFERENCIA) {
                sprintf(comando, "CRVI %d,%d", simbolo.nivel, simbolo.deslocamento);
            }
            else {
                sprintf(comando, "CRVL %d,%d", simbolo.nivel, simbolo.deslocamento);
            }
        }

        geraCodigo(NULL, comando);
        empilha_int(simbolo.tipo, pilha);

        return;
    }

    if (simbolo.forma == PARAMETRO_FORMAL && simbolo.param.passagem == REFERENCIA) {
        sprintf(comando, "CRVI %d,%d", simbolo.nivel, simbolo.deslocamento);
    }
    else {
        sprintf(comando, "CRVL %d,%d", simbolo.nivel, simbolo.deslocamento);
    }
    geraCodigo(NULL, comando);

    empilha_int(simbolo.tipo, pilha);

    return;
}

void empilhaFunc (int tipo, pilha_int *pilha) {
    if (tipo == SEM_TIPO)
      imprimeErro ("Operação não permitida (deveria ser uma função).");

    empilha_int(tipo, pilha);
    
    return;
}

void inserePilha (tabela_simbolos_t *ts, simbolo_t s) {
    if ((ts->topo + 1) == MAX_TABELA)
        imprimeErro("Tamanho maximo da tabela de simbolos atingido.");

    ts->topo = ts->topo + 1;
    ts->itens[ts->topo] = s;

    return;
}

simbolo_t removePilha (tabela_simbolos_t *ts) {
    if (ts->topo >= 0) {
        simbolo_t aux = ts->itens[ts->topo];
        ts->topo = ts->topo - 1;

        return aux;
    }
}