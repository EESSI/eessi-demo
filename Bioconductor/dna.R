library(Biostrings)
d <- DNAString("TTGAAAA-CTC-N")
length(d)  #no of letters in the DNAString

library(AnnotationHub)
ah <- AnnotationHub()
ah2 <- query(ah, c("fasta", "homo sapiens", "Ensembl", "cdna"))
dna <- ah2[["AH68262"]]
dna

getSeq(dna)
