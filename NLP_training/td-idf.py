# -*- coding: utf-8 -*-
"""
Created on Mon Dec 21 08:48:05 2020

@author: Peilin Yang
"""


import  math

sourcefile = '1.txt'
s2 = '2.txt'

# vector word frequency
def Count(resfile):
   t = {}
   infile = open(resfile, 'r', encoding='utf-8')
   f = infile.readlines()
   count = len(f)
   # print(count)
   infile.close()

   s = open(resfile, 'r', encoding='utf-8')
   i = 0
   while i < count:
       line = s.readline()
   
       line = line.rstrip('\n')
       # print(line)
       words = line.split(" ")
       #   print(words)

       for word in words:
           if word != "" and t.__contains__(word):
               num = t[word]
           t[word] = num + 1
           elif word!= "":
           t[word] = 1
       i = i + 1

        
       dic = sorted(t.items(), key=lambda t: t[1], reverse=True)
       # print(dic)
       # print()
       s.close()
       return (dic)



def MergeWord(T1,T2):
    MergeWord = []
    duplicateWord = 0
    for ch in range(len(T1)):
        MergeWord.append(T1[ch][0])
    for ch in range(len(T2)):
        if T2[ch][0] in MergeWord:
                duplicateWord = duplicateWord + 1
        else:
                MergeWord.append(T2[ch][0])

    # print(MergeWord)
    return MergeWord


def CalVector(T1,MergeWord):
    TF1 = [0] * len(MergeWord)

    for ch in range(len(T1)):
       TermFrequence = T1[ch][1]
       word = T1[ch][0]
       i = 0
       while i < len(MergeWord):
          if word == MergeWord[i]:
          TF1[i] = TermFrequence
          break
          else:
          i = i + 1
        # print(TF1)
       return TF1

def CalConDis(v1,v2,lengthVector):

       
        B = 0
        i = 0
        while i < lengthVector:
            B = v1[i] * v2[i] + B
            i = i + 1
        
        A = 0
        A1 = 0
        A2 = 0
        i = 0
        while i < lengthVector:
            A1 = A1 + v1[i] * v1[i]
            i = i + 1
        # print('A1 = ' + str(A1))

        i = 0
        while i < lengthVector:
            A2 = A2 + v2[i] * v2[i]
            i = i + 1
           # print('A2 = ' + str(A2))

        A = math.sqrt(A1) * math.sqrt(A2)
        print('similarity = ' + format(float(B) / A,".3f"))



T1 = Count(sourcefile)

print(T1)
print()
T2 = Count(s2)

print(T2)
print()

mergeword = MergeWord(T1,T2)
#  print(mergeword)
# print(len(mergeword))

v1 = CalVector(T1,mergeword)

print(v1)
print()
v2 = CalVector(T2,mergeword)

print(v2)
print()
# Cos Distance
CalConDis(v1,v2,len(v1))
