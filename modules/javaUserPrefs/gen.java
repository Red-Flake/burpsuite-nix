/*
 * Copyright (c) 2000, 2005, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

/*
 * Derived from OpenJDK's java.util.prefs.FileSystemPreferences and
 * java.util.prefs.Base64. Unused functionality has been removed.
 *
 * Sources:
 * - https://github.com/openjdk/jdk/blob/master/src/java.prefs/unix/classes/java/util/prefs/FileSystemPreferences.java
 * - https://github.com/openjdk/jdk/blob/master/src/java.prefs/share/classes/java/util/prefs/Base64.java
 */

public final class Gen {

    private Gen() {
    }

    public static void main(String[] args) {
        if (args.length != 2 || !"--directory".equals(args[0])) {
            System.err.println("Usage: java -jar gen.jar --directory <path>");
            System.exit(1);
        }

        // TODO: This is needed currently because of the module design, which should be changed in the Future
        String[] parts = args[1].split("/");

        StringBuilder result = new StringBuilder();

        for (String part : parts) {
            if (!part.isEmpty()) {
                if (result.length() > 0) {
                    result.append('/');
                }
                result.append(dirName(part));
            }
        }

        System.out.println(result);
    }

    /**
     * Returns true if the specified character is appropriate for use in
     * Unix directory names.  A character is appropriate if it's a printable
     * ASCII character (> 0x1f && < 0x7f) and unequal to slash ('/', 0x2f),
     * dot ('.', 0x2e), or underscore ('_', 0x5f).
     */
    private static boolean isDirChar(char ch) {
        return ch > 0x1f && ch < 0x7f && ch != '/' && ch != '.' && ch != '_';
    }

    /**
     * Returns the directory name corresponding to the specified node name.
     * Generally, this is just the node name.  If the node name includes
     * inappropriate characters (as per isDirChar) it is translated to Base64.
     * with the underscore  character ('_', 0x5f) prepended.
     */
    private static String dirName(String nodeName) {
        for (int i=0, n=nodeName.length(); i < n; i++)
            if (!isDirChar(nodeName.charAt(i)))
                return "_" + Base64.byteArrayToAltBase64(byteArray(nodeName));
        return nodeName;
    }

    /**
     * Translate a string into a byte array by translating each character
     * into two bytes, high-byte first ("big-endian").
     */
    private static byte[] byteArray(String s) {
        int len = s.length();
        byte[] result = new byte[2*len];
        for (int i=0, j=0; i<len; i++) {
            char c = s.charAt(i);
            result[j++] = (byte) (c>>8);
            result[j++] = (byte) c;
        }
        return result;
    }

    /**
     * Utility methods for the alternate Base64 encoding used by
     * java.util.prefs.FileSystemPreferences.
     */
    private static final class Base64 {

        private Base64() {
        }

        /**
         * Translates the specified byte array into an "alternate representation"
         * Base64 string.  This non-standard variant uses an alphabet that does
         * not contain the uppercase alphabetic characters, which makes it
         * suitable for use in situations where case-folding occurs.
         */
        private static String byteArrayToAltBase64(byte[] a) {
            int aLen = a.length;
            int numFullGroups = aLen/3;
            int numBytesInPartialGroup = aLen - 3*numFullGroups;
            int resultLen = 4*((aLen + 2)/3);
            StringBuilder result = new StringBuilder(resultLen);

            // Translate all full groups from byte array elements to Base64
            int inCursor = 0;
            for (int i=0; i<numFullGroups; i++) {
                int byte0 = a[inCursor++] & 0xff;
                int byte1 = a[inCursor++] & 0xff;
                int byte2 = a[inCursor++] & 0xff;
                result.append(intToAltBase64[byte0 >> 2]);
                result.append(intToAltBase64[(byte0 << 4)&0x3f | (byte1 >> 4)]);
                result.append(intToAltBase64[(byte1 << 2)&0x3f | (byte2 >> 6)]);
                result.append(intToAltBase64[byte2 & 0x3f]);
            }

            // Translate partial group if present
            if (numBytesInPartialGroup != 0) {
                int byte0 = a[inCursor++] & 0xff;
                result.append(intToAltBase64[byte0 >> 2]);
                if (numBytesInPartialGroup == 1) {
                    result.append(intToAltBase64[(byte0 << 4) & 0x3f]);
                    result.append("==");
                } else {
                    // assert numBytesInPartialGroup == 2;
                    int byte1 = a[inCursor++] & 0xff;
                    result.append(intToAltBase64[(byte0 << 4)&0x3f | (byte1 >> 4)]);
                    result.append(intToAltBase64[(byte1 << 2)&0x3f]);
                    result.append('=');
                }
            }
            return result.toString();
        }

        /**
         * This array is a lookup table that translates 6-bit positive integer
         * index values into their "Alternate Base64 Alphabet" equivalents.
         * This is NOT the real Base64 Alphabet as per in Table 1 of RFC 2045.
         * This alternate alphabet does not use the capital letters.  It is
         * designed for use in environments where "case folding" occurs.
         */
        private static final char intToAltBase64[] = {
            '!', '"', '#', '$', '%', '&', '\'', '(', ')', ',', '-', '.', ':',
            ';', '<', '>', '@', '[', ']', '^',  '`', '_', '{', '|', '}', '~',
            'a', 'b', 'c', 'd', 'e', 'f', 'g',  'h', 'i', 'j', 'k', 'l', 'm',
            'n', 'o', 'p', 'q', 'r', 's', 't',  'u', 'v', 'w', 'x', 'y', 'z',
            '0', '1', '2', '3', '4', '5', '6',  '7', '8', '9', '+', '?'
        };
    }
}