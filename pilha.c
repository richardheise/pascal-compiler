#include "pilha.h"

 
void inicializa_pilha (pilha_t *p) {
    p->topo = -1;
    return;
}

int pilha_vazia (pilha_t p) {
    if (p.topo == -1)
        return 1;
    
    return 0;
}

int empilha (void* x, pilha_t *p) {
    if (tamanho_pilha (*p) == MAX)
        return 0;

    p->topo = p->topo + 1;
    p->itens[p->topo] = x;

    return 1;
}
    
int desempilha (pilha_t *p) {
    if (pilha_vazia(*p))
        return 0;

    p->topo = p->topo - 1;

    return 1;
}

int topo (void* t, pilha_t p) {
    if (pilha_vazia (p))
        return 0;
    
    t = p.itens[p.topo];
    return 1;
}

int tamanho_pilha(pilha_t p) {
    return p.topo + 1;
}