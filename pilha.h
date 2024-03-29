#define MAX 10000
#define TAM_TOKEN 16

typedef struct pilha_t {
   int topo;
   char itens[MAX][TAM_TOKEN];
} pilha_t; 
 
void inicializa_pilha (pilha_t *p); /*inicializa pilha com -1 no topo*/

int pilha_vazia (pilha_t p); /*se a pilha eh vazia retorna 1, caso contrario retorna 0*/

int empilha (char* x, pilha_t *p);  /*empilha o elemento x no topo, se funcionar retorna 1, se não funcionar -- pilha cheia -- retorna 0*/

char* desempilha (pilha_t *p);

int tamanho_pilha (pilha_t p); /*retorna o tamanho da pilha*/

void imprime_pilha (pilha_t *p);