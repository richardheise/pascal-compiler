#include <stdio.h>
#include <string.h>
#include "tabela_simbolos.h"
 
void inicializa_tabela (tabela_simbolos_t *ts) {
    ts->topo = -1;
    return;
}

void insere (tabela_simbolos_t *ts, simbolo_t s) {
    if ((ts->topo + 1) == MAX_TABELA)
        return;

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
        if (strcmp(aux, ts.itens[i].var.nome) == 0)
            return ts.itens[i];
    }

    simbolo_t s;
    s.tipo = -1;
    return s;
}

void imprime (tabela_simbolos_t ts) {
    for (int i = 0; i <= ts.topo; i++) {
        switch (ts.itens[i].tipo) {
            case VARIAVEL: printf ("%s VARIAVEL Tipo:%d Nivel:%d Deslocamento:%d\n", ts.itens[i].var.nome, ts.itens[i].var.tipo, ts.itens[i].var.nivel, ts.itens[i].var.deslocamento);break;
            case PARAMETRO_FORMAL: printf ("%s PARAMETRO_FORMAL Tipo:%d Nivel:%d Deslocamento:%d Passagem:%d\n", ts.itens[i].param.nome, ts.itens[i].param.tipo, ts.itens[i].param.nivel, ts.itens[i].param.deslocamento, ts.itens[i].param.passagem);break;
            case PROCEDIMENTO: printf ("%s PROCEDIMENTO Rot:%s Param:%d\n", ts.itens[i].proc.nome, ts.itens[i].proc.rotulo, ts.itens[i].proc.num_param);break;
            case FUNCAO: printf ("%s FUNCAO\n", ts.itens[i].func.nome);break;
        }
    }

    return;
}

void insereVarTabela (tabela_simbolos_t *ts, char* token, int nivel, int deslocamento) {
    variavel_t v;
    simbolo_t s;

    strncpy(v.nome, token, TAM_TOKEN);
    v.nivel = nivel;
    v.deslocamento = deslocamento;
    
    s.tipo = VARIAVEL;
    s.var = v;
    insere (ts, s);
}

void insereProcTabela (tabela_simbolos_t *ts, char* token, char* rotulo, int nivel) {
    procedimento_t p;
    simbolo_t s;

    strncpy(p.nome, token, TAM_TOKEN);
    strncpy(p.rotulo, rotulo, TAM_TOKEN);
    p.nivel = nivel;
    p.num_param = 0;
    
    s.tipo = PROCEDIMENTO;
    s.proc = p;
    insere (ts, s);
}

void insereParamTabela (tabela_simbolos_t *ts, char* token, int nivel, int passagem) {
    parametro_formal_t pf;
    simbolo_t s;

    strncpy(pf.nome, token, TAM_TOKEN);
    pf.nivel = nivel;
    pf.passagem = passagem;
    
    s.tipo = PARAMETRO_FORMAL;
    s.param = pf;
    insere (ts, s);
}

void atualizaTipoVar (tabela_simbolos_t *ts, int tipo, int quant) {
    for (int i = ts->topo; quant > 0; i--) {
        ts->itens[i].var.tipo = tipo;
        quant--;
    }
}

void atualizaTipoParam (tabela_simbolos_t *ts, int tipo, int quant) {
    for (int i = ts->topo; quant > 0; i--) {
        ts->itens[i].param.tipo = tipo;
        quant--;
    }
}

void atualizaDeslocamentoParam (tabela_simbolos_t *ts, int nivel, int quant) {
    int deslocamento = -4;
    int iProc;
    iProc = ts->topo - quant;
    ts->itens[iProc].proc.num_param = quant;

    for (int i = ts->topo; quant > 0; i--) {
        ts->itens[i].param.deslocamento = deslocamento;

        ts->itens[iProc].proc.tipo_param[quant - 1] = ts->itens[i].param.tipo;
        ts->itens[iProc].proc.passagem_param[quant - 1] = ts->itens[i].param.passagem;
        
        quant--;
        deslocamento--;
    }
}

int quantVariaveis (tabela_simbolos_t ts, int nivel) {
    for (int i = ts.topo; i >= 0; i--) {
        if ((ts.itens[i].tipo == VARIAVEL) && (ts.itens[i].var.nivel == nivel))
            return ts.itens[i].var.deslocamento + 1;
    }

    return 0;
}

simbolo_t buscaSimbolo (tabela_simbolos_t tabela, char* nome) {
  simbolo_t simbolo = busca (tabela, nome);
  char comando[100];

  if (simbolo.tipo == -1) {
      sprintf(comando, "Variavel %s não encontrada.", nome);
      imprimeErro (comando);
  }

  return simbolo;
}

void validaTipos (pilha_t* pilha, tabela_simbolos_t tabela, int tipo) {
    char *v1 = desempilha (pilha);
    char *v2 = desempilha (pilha);

    int t1;
    int t2;
    if (strcmp(v1, "INT") == 0)
        t1 = INT;
    else if (strcmp(v1, "BOOL") == 0)
        t1 = BOOL;

    if (strcmp(v2, "INT") == 0)
        t2 = INT;
    else if (strcmp(v2, "BOOL") == 0)
        t2 = BOOL;

    
    if ((t1 != tipo) || (t1 != t2))
        imprimeErro ("Operação invalida.");

    return;
}

void empilhaNUM(char *token, pilha_t *pilha) {
    char comando[100];

    sprintf(comando, "CRCT %s", token);
    geraCodigo(NULL, comando);
    empilha("INT", pilha);

    return;
}

void empilhaIDENT(char *token, int ivar, int quantFator, int tipoOP, procedimento_t proc, pilha_t *pilha, tabela_simbolos_t tabela) {
    char comando[100];
    simbolo_t simbolo = buscaSimbolo(tabela, token);

    if (tipoOP == PROC) {
        if (ivar >= proc.num_param)
            imprimeErro ("Parametro .");

        if (proc.passagem_param[ivar] == REFERENCIA) {
            if (quantFator > 1)
                imprimeErro ("Parametro invalido.");


            if (simbolo.tipo == PARAMETRO_FORMAL && simbolo.param.passagem == REFERENCIA) {
                sprintf(comando, "CRVL %d,%d", simbolo.var.nivel, simbolo.var.deslocamento);
            }
            else {
                sprintf(comando, "CREN %d,%d", simbolo.var.nivel, simbolo.var.deslocamento);
            }
        }
        else {
            if (simbolo.tipo == PARAMETRO_FORMAL && simbolo.param.passagem == REFERENCIA) {
                sprintf(comando, "CRVI %d,%d", simbolo.var.nivel, simbolo.var.deslocamento);
            }
            else {
                sprintf(comando, "CRVL %d,%d", simbolo.var.nivel, simbolo.var.deslocamento);
            }
        }

        geraCodigo(NULL, comando);
        if (simbolo.var.tipo == INT)
            empilha("INT", pilha);
        else
            empilha("BOOL", pilha);

        return;
    }

    sprintf(comando, "CRVL %d,%d", simbolo.var.nivel, simbolo.var.deslocamento);
    geraCodigo(NULL, comando);

    if (simbolo.var.tipo == INT)
        empilha("INT", pilha);
    else
        empilha("BOOL", pilha);

    return;
}
