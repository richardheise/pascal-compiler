#define MAX 10000

enum tipo_variavel { INT, BOOL };
enum tipo_passagem { VALOR, COPIA };

typedef struct {
   char *nome;
   int nivel;
   int deslocamento;
   int tipo;
} variavel_t;

typedef struct {
   char *nome;
   int nivel;
   int deslocamento;
   int tipo;
   int passagem;
} parametro_formal_t;

typedef struct {
   char *nome;
   int linha;
} rotulo_t;

typedef struct {
   char *nome;
   int nivel;
   rotulo_t rotulo;
   int num_param;
   int *tipo_param;
   int *passagem_param;
} procedimento_t;

typedef struct {
   char *nome;
   int nivel;
   int tipo_retorno;
   rotulo_t rotulo;
   int num_param;
   int *tipo_param;
   int *passagem_param;
} funcao_t;


typedef struct {
   union {
      variavel_t var;
      parametro_formal_t param;
      procedimento_t proc;
      funcao_t func;
      rotulo_t rot;
   };
   enum tipo_simbolo { VARIAVEL, PARAMETRO_FORMAL, PROCEDIMENTO, FUNCAO, ROTULO } tipo;
} simbolo_t;


typedef struct {
   int topo;
   simbolo_t itens[MAX];
} tabela_simbolos_t;


 
void inicializa_tabela (tabela_simbolos_t *ts);

void insere (tabela_simbolos_t *ts, simbolo_t s); 

void retira (tabela_simbolos_t *ts, int n); 

simbolo_t busca (tabela_simbolos_t ts, char* nome);

void imprime (tabela_simbolos_t ts);