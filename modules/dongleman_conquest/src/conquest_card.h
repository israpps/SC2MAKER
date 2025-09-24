#ifndef CONQUEST_H
#define CONQUEST_H

/**
 * @file conquest_card.h
 * methods for special exports of MCMAN capable of handling conquest card
 */

int nmConquestPageErase(int port, int slot, int page); // #56
int nmConquestPageRead(int port, int slot, int page, int size, void *buf); // #57
int nmConquestPageWrite(int port, int slot, int page, int size, void *buf); // #58
int nmConquestAuthCard(int port, int slot); // #59


#define I_nmConquestPageErase DECLARE_IMPORT(56, nmConquestPageErase) // #56
#define I_nmConquestPageRead  DECLARE_IMPORT(57, nmConquestPageRead ) // #57
#define I_nmConquestPageWrite DECLARE_IMPORT(58, nmConquestPageWrite) // #58
#define I_nmConquestAuthCard  DECLARE_IMPORT(59, nmConquestAuthCard ) // #59

#endif
