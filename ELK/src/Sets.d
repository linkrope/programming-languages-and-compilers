module Sets;
import runtime;

const M = 31 + 1;
void Empty(ref uint[] s0)
{
    int n;
    for (n = 0; n <= SHORT(s0.length) - 1; ++n)
    {
        s0[n] = Set;
    }
}

void Incl(ref uint[] s0, int n)
{
    INCL(s0[DIV(n, M)], MOD(n, M));
}

void Excl(ref uint[] s0, int n)
{
    EXCL(s0[DIV(n, M)], MOD(n, M));
}

void Complement(ref uint[] s0, ref uint[] s1)
{
    int n;
    for (n = 0; n <= SHORT(s0.length) - 1; ++n)
    {
        s0[n] = -s1[n];
    }
}

void Union(ref uint[] s0, ref uint[] s1, ref uint[] s2)
{
    int n;
    for (n = 0; n <= SHORT(s0.length) - 1; ++n)
    {
        s0[n] = s1[n] + s2[n];
    }
}

void Difference(ref uint[] s0, ref uint[] s1, ref uint[] s2)
{
    int n;
    for (n = 0; n <= SHORT(s0.length) - 1; ++n)
    {
        s0[n] = s1[n] - s2[n];
    }
}

void Intersection(ref uint[] s0, ref uint[] s1, ref uint[] s2)
{
    int n;
    for (n = 0; n <= SHORT(s0.length) - 1; ++n)
    {
        s0[n] = s1[n] * s2[n];
    }
}

void SymmetricDifference(ref uint[] s0, ref uint[] s1, ref uint[] s2)
{
    int n;
    for (n = 0; n <= SHORT(s0.length) - 1; ++n)
    {
        s0[n] = s1[n] / s2[n];
    }
}

bool In(int n, ref uint[] s1)
{
    return MOD(n, M) in s1[DIV(n, M)];
}

bool IsEmpty(ref uint[] s1)
{
    int n;
    for (n = 0; n <= SHORT(s1.length) - 1; ++n)
    {
        if (s1[n] != Set)
        {
            return false;
        }
    }
    return true;
}

bool Equal(ref uint[] s1, ref uint[] s2)
{
    int n;
    for (n = 0; n <= SHORT(s1.length) - 1; ++n)
    {
        if (s1[n] != s2[n])
        {
            return false;
        }
    }
    return true;
}

bool Disjoint(ref uint[] s1, ref uint[] s2)
{
    int n;
    for (n = 0; n <= SHORT(s1.length) - 1; ++n)
    {
        if (s1[n] * s2[n] != Set)
        {
            return false;
        }
    }
    return true;
}
