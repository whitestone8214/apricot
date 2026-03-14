/*
	Copyright (C) 2026 Minho Jo <whitestone8214@gmail.com> <goguma200@protonmail.com>
	
	SPDX-License-Identifier: GPL-2.0
	
	Build: gcc -o helper -O3 -fPIC helper.c
*/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>


int main(int nOptions, char **listOptions);
void swansong(char *message);


int main(int nOptions, char **listOptions) {
	if (nOptions < 3) swansong("ng");
	
	if (strcmp(listOptions[1], "check-uboot-size") == 0) {
		struct stat _aboutFile;
		if (stat(listOptions[2], &_aboutFile) != 0) swansong("ng");
		
		int _sizeLimit = (1024 * 1024) - 2048;
		if (_aboutFile.st_size > _sizeLimit) swansong("ng");
	}
	
	printf("ok");
	return 0;
}
void swansong(char *message) {
	printf("%s", message);
	exit(-1);
}
