#include <stdio.h>
#include <string.h>
#include "tabela_simbolos.h"
 
void inicializa_tabela (tabela_simbolos_t *ts) {
    ts->topo = -1;
    return;
}

void insere (tabela_simbolos_t *ts, simbolo_t s) {
    if ((ts->topo + 1) == MAX)
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
    for (int i = ts.topo; i >= 0; i--) {
        if (strcmp(nome, ts.itens[i].var.nome) == 0)
            return ts.itens[i];
    }

    simbolo_t s;
    s.tipo = -1;
    return s;
}

void imprime (tabela_simbolos_t ts) {
    for (int i = 0; i <= ts.topo; i++) {
        switch (ts.itens[i].tipo) {
            case VARIAVEL: printf ("%s %s\n", ts.itens[i].var.nome, "VARIAVEL");break;
            case PARAMETRO_FORMAL: printf ("%s %s\n", ts.itens[i].param.nome, "PARAMETRO_FORMAL");break;
            case PROCEDIMENTO: printf ("%s %s\n", ts.itens[i].proc.nome, "PROCEDIMENTO");break;
            case FUNCAO: printf ("%s %s\n", ts.itens[i].func.nome, "FUNCAO");break;
            case ROTULO: printf ("%s %s\n", ts.itens[i].rot.nome, "ROTULO");break;
        }
    }

    return;
}