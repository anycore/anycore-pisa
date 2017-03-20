#ifndef _BP_TABLE_H
#define _BP_TABLE_H

#include "ss.h"

class bp_table {

private:

  //////////////////////////
  //  Memory
  ////////////////////////// 
  char *text_mem_table[MEMORY_TABLE_SIZE];
  char *mem_table[MEMORY_TABLE_SIZE];

  // ER 11/16/02
  unsigned int Tid;

  //////////////////////////
  // Number of loads and stores.
  unsigned int n_load;
  unsigned int n_store;

  //////////////////////////
  //  Private functions
  //////////////////////////

  // Allocate a chunk of memory.
  char *mem_newblock(void);


public:

  bp_table(unsigned int Tid) {

  unsigned int i,j;

  this->ld_text_size = ld_text_size;

  for (unsigned int i = 0; i < MEMORY_TABLE_SIZE; i++)
    mem_table[i] = (char *)NULL;

  // STATS

  } // Constructor

  void copy_table(char **master_mem_table);
  void copy_text_mem(char **master_mem_table);

  // STATS
  void stats(FILE *fp);


  // Wrapper function to read from/write to memory

  unsigned char get_counter(unsigned int addr) {
    return (BPTAB[addr]);
  }    
      
  void set_counter(unsigned int addr, unsigned int value) {
    BPTAB[addr] = value;
  }    

}; 


#endif
