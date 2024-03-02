#define MAX 1000

typedef struct pilha_t {
   int topo;
   void*  itens[MAX];
} pilha_t; 
 
void inicializa_pilha (pilha_t *p); /*inicializa pilha com -1 no topo*/

int pilha_vazia (pilha_t p); /*se a pilha eh vazia retorna 1, caso contrario retorna 0*/

int empilha (void* x, pilha_t *p);  /*empilha o elemento x no topo, se funcionar retorna 1, se não funcionar -- pilha cheia -- retorna 0*/

int desempilha (pilha_t *p); /*desempilha o elemento do topo, se funcionar retorna 1, caso contrario -- pilha vazia -- retorna 0*/

int topo (void* t, pilha_t p); /*retorna o elemento do topo, se funcionar retorna 1, caso contrário -- pilha vazia -- retorna 0*/

int tamanho_pilha (pilha_t p); /*retorna o tamanho da pilha*/