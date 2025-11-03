#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <lzo/lzo1x.h>

// 定义输入/输出缓冲区大小 (例如：每次处理 256KB)
#define IN_LEN (256 * 1024L)
// LZO 压缩后可能会略微变大，所以输出缓冲区要大一点
#define OUT_LEN (IN_LEN + IN_LEN / 16 + 64 + 3)

// LZO 所需的工作内存
static unsigned char wrkmem[LZO1X_1_MEM_COMPRESS];

int main(int argc, char *argv[]) {
    unsigned char *in_buf;
    unsigned char *out_buf;
    lzo_uint in_len;
    lzo_uint out_len;
    
    // 1. 初始化 LZO 库
    if (lzo_init() != LZO_E_OK) {
        fprintf(stderr, "Error: lzo_init() failed.\n");
        return 1;
    }

    // 2. 分配内存
    in_buf = (unsigned char *) malloc(IN_LEN);
    out_buf = (unsigned char *) malloc(OUT_LEN);
    if (in_buf == NULL || out_buf == NULL) {
        fprintf(stderr, "Error: Cannot allocate memory.\n");
        return 1;
    }

    // 3. 循环从标准输入读取数据
    while ((in_len = read(STDIN_FILENO, in_buf, IN_LEN)) > 0) {
        
        // 4. 调用 LZO1X 压缩函数
        // lzo1x_1_compress 是一个快速的变体
        int r = lzo1x_1_compress(in_buf, in_len, out_buf, &out_len, wrkmem);

        if (r != LZO_E_OK) {
            fprintf(stderr, "Error: LZO compression failed.\n");
            return 1;
        }

        // 5. 将原始压缩数据写入标准输出
        if (write(STDOUT_FILENO, out_buf, out_len) != out_len) {
            fprintf(stderr, "Error: Write error.\n");
            return 1;
        }
    }

    free(in_buf);
    free(out_buf);
    return 0;
}
