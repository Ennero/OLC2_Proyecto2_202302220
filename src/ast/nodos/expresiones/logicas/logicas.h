#ifndef LOGICAS_H
#define LOGICAS_H

#include "ast/nodos/expresiones/expresiones.h"
#include <stdbool.h>

static inline bool convertirResultadoLogico(const Result *res, int *out)
{
	if (!res || !out)
		return false;

	switch (res->tipo)
	{
	case BOOLEAN:
		if (!res->valor)
		{
			*out = 0;
			return true;
		}
		*out = (*((int *)res->valor) != 0) ? 1 : 0;
		return true;
	case INT:
	case CHAR:
		if (!res->valor)
		{
			*out = 0;
			return true;
		}
		*out = (*((int *)res->valor) != 0) ? 1 : 0;
		return true;
	case FLOAT:
		if (!res->valor)
		{
			*out = 0;
			return true;
		}
		*out = (*((float *)res->valor) != 0.0f) ? 1 : 0;
		return true;
	case DOUBLE:
		if (!res->valor)
		{
			*out = 0;
			return true;
		}
		*out = (*((double *)res->valor) != 0.0) ? 1 : 0;
		return true;
	case STRING:
		if (!res->valor)
		{
			*out = 0;
			return true;
		}
		*out = (((char *)res->valor)[0] != '\0') ? 1 : 0;
		return true;
	case NULO:
		*out = 0;
		return true;
	default:
		return false;
	}
}

#endif // LOGICAS_H