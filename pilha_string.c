#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pilha_string.h"

 
void inicializa_pilha_str (pilha_t *p) {
    p->topo = -1;
    return;
}

int pilha_vazia_str (pilha_t p) {
    if (p.topo == -1)
        return 1;
    
    return 0;
}

int empilha_str (char* x, pilha_t *p) {
    if (tamanho_pilha_str (*p) == MAX)
        return 0;

    p->topo = p->topo + 1;
    strncpy(p->itens[p->topo], x, TAM_TOKEN);

    return 1;
}
    
char* desempilha_str (pilha_t *p) {
    if (pilha_vazia_str(*p))
        return 0;

    char* aux = p->itens[p->topo];
    p->topo = p->topo - 1;
    
    return aux;
}

int tamanho_pilha_str(pilha_t p) {
    return p.topo + 1;
}

void imprime_pilha_str (pilha_t *p) {
    for (int i = 0; i <= p->topo; i++)
        printf ("%s\n", p->itens[i]);
}