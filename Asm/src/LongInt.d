module LongInt;
import runtime;

bool OK;
void Inc(ref long z)
{
    OK = z < long.max;
    if (OK)
    {
        ++z;
    }
}

void Dec(ref long z)
{
    OK = z > long.min;
    if (OK)
    {
        --z;
    }
}

void Neg(ref long z, long x)
{
    OK = z != long.min;
    if (OK)
    {
        z = -x;
    }
}

void Add(ref long z, long x, long y)
{
    OK = x >= 0 != y >= 0 || y >= 0 && x <= long.max - y || y < 0 && x >= long.min - y;
    if (OK)
    {
        z = x + y;
    }
}

void Sub(ref long z, long x, long y)
{
    OK = x >= 0 == y >= 0 || y < 0 && x <= long.max + y || y >= 0 && x >= long.min + y;
    if (OK)
    {
        z = x - y;
    }
}

void Mul(ref long z, long x, long y)
{
    if (y == 0)
    {
        OK = true;
    }
    else
    {
        if (x >= 0)
        {
            if (y > 0)
            {
                OK = x <= DIV(long.max, y);
            }
            else
            {
                OK = y == -1 || x <= DIV(long.min, y);
            }
        }
        else
        {
            if (y > 0)
            {
                OK = x >= DIV(long.min, y);
            }
            else
            {
                OK = x >= DIV(long.max, y);
            }
        }
    }
    if (OK)
    {
        z = x * y;
    }
}

void Div(ref long z, long x, long y)
{
    OK = y != 0;
    if (OK)
    {
        if (x == long.min && y == -1)
        {
            OK = false;
        }
        else
        {
            z = DIV(x, y);
        }
    }
}

void Mod(ref long z, long x, long y)
{
    OK = y != 0;
    if (OK)
    {
        if (x == long.min && y == -1)
        {
            z = 0;
        }
        else
        {
            z = MOD(x, y);
        }
    }
}
