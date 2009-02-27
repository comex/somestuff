# A LOT faster than the python version, which has to allocate new strings for setslice
cdef extern from "Python.h":
    object PyString_FromStringAndSize(char *s, Py_ssize_t len)

cdef extern from "stdlib.h":
    void *memcpy(void *dest, void *src, int size)
    void *malloc(int size)
    void free(void *ptr)

cdef inline char* mycopy(char* dest, int plus, char* frum, int size):
    memcpy(dest + plus, frum, size)
cdef object my_sas(char *st, int offs, int len):
    return PyString_FromStringAndSize(st + offs, len)
cdef class MutableString:
    cdef char* mystring
    cdef int size
    def __cinit__(self):
        self.mystring = <char*> 0
    def __init__(self, st):
        cdef int sz = len(st)
        self.mystring = <char *> malloc(sz)
        memcpy(<void *> self.mystring, <void *> (<char *>st), sz)
        self.size = sz
    def __dealloc__(self):
        if <int>(self.mystring) != 0:
            free(<void *> self.mystring)
    def __getslice__(self, i, j):
        # From stringobject.c
        if i < 0: i = 0
        if j < 0: j = 0
        if j > self.size: j = self.size
        if j < i: j = i
        return my_sas(self.mystring, i, j - i)
    def __setslice__(self, i, j, st):
        if i < 0: i = 0
        if j < 0: j = 0
        if j > self.size: j = self.size
        if j < i: j = i
        cdef int sz = j - i
        if sz != len(st):
            raise Exception('Wrong size.')
        mycopy(self.mystring, i, st, j-i)
    def __len__(self):
        return self.size
    def __str__(self):
        return PyString_FromStringAndSize(self.mystring, self.size)
    def __repr__(self):
        return 'm' + repr(str(self))
