import string from std.ascii
import File from std.fs
import std.array
import std.io

// Author: David J. Pearce

// ========================================================
// Description
// ========================================================

// This is a very naive implementation of matrix multiplication.  It does
// not perform any optimisations, and does not represent matrices in any
// special manner (e.g. sparse representations, etc).
//
// In the future, it would be interesting to consider chain
// multiplication problem:
//
// http://en.wikipedia.org/wiki/Matrix_chain_multiplication
//

// ========================================================
// Benchmark Code
// ========================================================

type nat is (int x) where x >= 0

type Matrix is ({
    int width,
    int height,
    int[][] data
} m) where |m.data| == m.height && all { i in 0..m.height | |m.data[i]| == m.width }

function Matrix(nat width, nat height, int[][] data) -> (Matrix r)
// Input array must match matrix height
requires |data| == height
// Elements of input array must match matrix width
requires all { i in 0..height | |data[i]| == width }
//
ensures r.width == width && r.height == height && r.data == data:
    //
    return {
        width: width,
        height: height,
        data: data
    }

function multiply(Matrix A, Matrix B) -> (Matrix C)
// Must be possible to multiply matrices
requires A.width == B.height
// Specify dimensions of result
ensures C.width == B.width && C.height == A.height:
    //
    int[][] C_data = [[0;B.width];A.height]
    nat i = 0
    //
    // NOTE: the following loops can be more elegantly written using
    // "for" statements.  However, for the moment I use "while"
    // statements as these work better with verification.
    //
    while i < A.height:
        nat j = 0
        while j < B.width:
            int r = 0
            nat k = 0
            while k < A.width:
                r = r + (A.data[i][k] * B.data[k][j])
                k = k + 1
            C_data[i][j] = r
            j = j + 1
        i = i + 1
    //
    return Matrix(B.width,A.height,C_data)

// ========================================================
// Parser Code
// ========================================================

function parseFile(string input) -> (Matrix|null a,Matrix|null b):
    Matrix|null A // 1st result
    Matrix|null B // 2nd result
    int[]|null data
    int pos
    data,pos = parseLine(2,0,input)
    // santity check    
    if data != null:
        int nrows = data[0]
        int ncols = data[1]
        pos = skipBreak(pos,input)
        A,pos = parseMatrix(nrows,ncols,pos,input)
        pos = skipBreak(pos,input)
        B,pos = parseMatrix(nrows,ncols,pos,input)
        return A,B
    //
    return null,null

function parseMatrix(nat height, nat width, int pos, string input) -> (Matrix|null m, int npos):
    //
    int[][] rows = [[0;0];height]
    int[]|null row
    int i = 0
    //
    while i < height:
        row,pos = parseLine(width,pos,input)
        if row == null:
            return null,pos
        else:
            rows[i] = row
        i = i + 1
    //
    return Matrix(width,height,rows),pos

function parseLine(int count, int pos, string input) -> (int[]|null data,int npos):
    //
    pos = skipWhiteSpace(pos,input)
    int[] ints = [0;0]
    int|null i
    //
    while pos < |input| && |ints| != count:
        i,pos = parseInt(pos,input)
        if i != null:
            ints = array.append(ints,i)
            pos = skipWhiteSpace(pos,input)
        else:
            return null,pos
    //
    if |ints| != count:
        return null,pos
    else:
        return ints,pos

function parseInt(int pos, string input) -> (int|null data,int npos):
    //
    int start = pos
    // check for negative input
    if pos < |input| && input[pos] == '-':
        pos = pos + 1
    // match remainder
    while pos < |input| && ascii.isDigit(input[pos]):
        pos = pos + 1
    // check for error
    if pos == start:
        return null,pos
    else:
        string tmp = array.slice(input,start,pos)
        return ascii.parseInt(tmp),pos

function skipBreak(int index, string input) -> int:
    while index < |input| && input[index] == '-':
        index = index + 1
    //
    return skipWhiteSpace(index,input)

function skipWhiteSpace(int index, string input) -> int:
    while index < |input| && isWhiteSpace(input[index]):
        index = index + 1
    //
    return index

function isWhiteSpace(ascii.char c) -> bool:
    return c == ' ' || c == '\t' || c == '\r' || c == '\n'

// ========================================================
// Main
// ========================================================

method printMat(Matrix A):
    int i = 0
    while i < A.height:
        int j = 0
        while j < A.width:
            io.print(A.data[i][j])
            io.print(" ")
            j = j + 1
        i = i + 1
        io.println(" ")

method main(string[] args):
    if |args| == 0:
        io.println("usage: matrix <input-file>")
    else:
        File file = fs.open(args[0])
        // first, read data
        string input = ascii.fromBytes(file.readAll())
        // second, build the matrices
        null|Matrix A
        null|Matrix B
        //
        A,B = parseFile(input)
        // third, sanity check we succeeded
        if A is null || B is null:
            io.println("error parsing input")
        else:
            // fourth, run the benchmark
            Matrix C = multiply(A,B)
            // finally, print the result!
            printMat(C)


