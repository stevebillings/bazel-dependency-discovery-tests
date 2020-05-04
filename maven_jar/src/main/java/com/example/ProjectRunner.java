package com.example;

import com.google.common.math.IntMath;

public class ProjectRunner {
    public static void main(String args[]) {
        Greeting.sayHi();
	System.out.printf("isPowerOfTwo(1): %b\n", IntMath.isPowerOfTwo(1));
    }
}
