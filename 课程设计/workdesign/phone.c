#include "phone.h"

/* ===================== 全局变量（只在这里定义一次） ===================== */
Customer customers[MAX_CUSTOMERS];
int      cust_cnt = 0;

char call_from[MAX_CALLS][PHONE_LEN];
char call_to  [MAX_CALLS][PHONE_LEN];
int  call_cnt = 0;

OASlot   phone_oa[PHONE_TABLE_SIZE];
ChainNode *phone_ch[PHONE_TABLE_SIZE];
OASlot   name_oa[NAME_TABLE_SIZE];
ChainNode *name_ch[NAME_TABLE_SIZE];

/* ===================== 工具函数 ===================== */

/* 将11位手机号转为无符号长整数 */
static unsigned long phone_to_ul(const char *phone) {
    unsigned long v = 0;
    for (int i = 0; i < 11 && phone[i]; i++)
        v = v * 10 + (phone[i] - '0');
    return v;
}

/* ---- 哈希函数1：除留余数法 ---- */
static int hash_div_phone(const char *phone, int size) {
    unsigned long v = phone_to_ul(phone);
    return (int)(v % (unsigned long)size);
}

static int hash_div_name(const char *name, int size) {
    unsigned long v = 0;
    for (int i = 0; name[i]; i++)
        v = v * 31 + (unsigned char)name[i];
    return (int)(v % (unsigned long)size);
}

/* ---- 哈希函数2：折叠法（将手机号每3位相加后取模）---- */
static int hash_fold_phone(const char *phone, int size) {
    char buf[12];
    strncpy(buf, phone, 11);
    buf[11] = '\0';
    unsigned long p1 = 0, p2 = 0, p3 = 0;
    for (int i = 0; i < 3 && buf[i]; i++) p1 = p1 * 10 + (buf[i] - '0');
    for (int i = 3; i < 7 && buf[i]; i++) p2 = p2 * 10 + (buf[i] - '0');
    for (int i = 7; i < 11 && buf[i]; i++) p3 = p3 * 10 + (buf[i] - '0');
    return (int)((p1 + p2 + p3) % (unsigned long)size);
}

static int hash_fold_name(const char *name, int size) {
    unsigned long sum = 0;
    int len = (int)strlen(name);
    for (int i = 0; i < len; i += 4) {
        unsigned long chunk = 0;
        for (int j = i; j < i + 4 && j < len; j++)
            chunk = chunk * 256 + (unsigned char)name[j];
        sum += chunk;
    }
    return (int)(sum % (unsigned long)size);
}

/* 统一入口 */
static int hash_phone(const char *phone, int size, int htype) {
    return htype == HASH_DIV ? hash_div_phone(phone, size)
                             : hash_fold_phone(phone, size);
}
static int hash_name(const char *name, int size, int htype) {
    return htype == HASH_DIV ? hash_div_name(name, size)
                             : hash_fold_name(name, size);
}

/* ===================== 文件读取 ===================== */

int load_customers(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) { printf("无法打开 %s\n", filename); return -1; }
    cust_cnt = 0;
    while (cust_cnt < MAX_CUSTOMERS &&
           fscanf(fp, "%31s %18s %11s",
                  customers[cust_cnt].name,
                  customers[cust_cnt].id,
                  customers[cust_cnt].phone) == 3) {
        customers[cust_cnt].call_count = 0;
        cust_cnt++;
    }
    fclose(fp);
    printf("已加载 %d 位顾客信息。\n", cust_cnt);
    return cust_cnt;
}

int load_calls(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) { printf("无法打开 %s\n", filename); return -1; }
    call_cnt = 0;
    while (call_cnt < MAX_CALLS &&
           fscanf(fp, "%11s %11s", call_from[call_cnt], call_to[call_cnt]) == 2)
        call_cnt++;
    fclose(fp);
    printf("已加载 %d 条通话记录。\n", call_cnt);
    return call_cnt;
}

/* ===================== 统计通话次数 ===================== */
void count_calls(void) {
    for (int i = 0; i < cust_cnt; i++) customers[i].call_count = 0;
    for (int k = 0; k < call_cnt; k++) {
        for (int i = 0; i < cust_cnt; i++) {
            if (strcmp(customers[i].phone, call_from[k]) == 0) customers[i].call_count++;
            if (strcmp(customers[i].phone, call_to[k])   == 0) customers[i].call_count++;
        }
    }
}

/* ===================== 开放寻址哈希表 ===================== */

void oa_init(OASlot *table, int size) {
    for (int i = 0; i < size; i++) table[i].valid = 0;
}

/* 插入，返回探测次数 */
int oa_insert_phone(OASlot *table, int size, int cust_idx, int htype) {
    int h = hash_phone(customers[cust_idx].phone, size, htype);
    int probe = 1;
    for (int step = 0; step < size; step++, probe++) {
        int pos = (h + step) % size;
        if (table[pos].valid != 1) {
            table[pos].valid = 1;
            table[pos].cust_idx = cust_idx;
            return probe;
        }
    }
    return probe;
}

int oa_insert_name(OASlot *table, int size, int cust_idx, int htype) {
    int h = hash_name(customers[cust_idx].name, size, htype);
    int probe = 1;
    for (int step = 0; step < size; step++, probe++) {
        int pos = (h + step) % size;
        if (table[pos].valid != 1) {
            table[pos].valid = 1;
            table[pos].cust_idx = cust_idx;
            return probe;
        }
    }
    return probe;
}

/* 按手机号查找 */
int oa_find_phone(OASlot *table, int size, const char *phone, int htype) {
    int h = hash_phone(phone, size, htype);
    for (int step = 0; step < size; step++) {
        int pos = (h + step) % size;
        if (table[pos].valid == 0) return -1;
        if (table[pos].valid == 1 &&
            strcmp(customers[table[pos].cust_idx].phone, phone) == 0)
            return table[pos].cust_idx;
    }
    return -1;
}

/* 按姓名查找 */
int oa_find_name(OASlot *table, int size, const char *name, int htype) {
    int h = hash_name(name, size, htype);
    for (int step = 0; step < size; step++) {
        int pos = (h + step) % size;
        if (table[pos].valid == 0) return -1;
        if (table[pos].valid == 1 &&
            strcmp(customers[table[pos].cust_idx].name, name) == 0)
            return table[pos].cust_idx;
    }
    return -1;
}

/* ===================== 链地址哈希表 ===================== */

void ch_init(ChainNode **table, int size) {
    for (int i = 0; i < size; i++) table[i] = NULL;
}

void ch_free(ChainNode **table, int size) {
    for (int i = 0; i < size; i++) {
        ChainNode *p = table[i];
        while (p) { ChainNode *q = p->next; free(p); p = q; }
        table[i] = NULL;
    }
}

/* 插入，返回链上位置（1=表头） */
int ch_insert_phone(ChainNode **table, int size, int cust_idx, int htype) {
    int h = hash_phone(customers[cust_idx].phone, size, htype);
    ChainNode *node = (ChainNode *)malloc(sizeof(ChainNode));
    node->cust_idx = cust_idx;
    node->next = table[h];
    table[h] = node;
    int len = 0;
    ChainNode *p = table[h];
    while (p) { len++; p = p->next; }
    return len;
}

int ch_insert_name(ChainNode **table, int size, int cust_idx, int htype) {
    int h = hash_name(customers[cust_idx].name, size, htype);
    ChainNode *node = (ChainNode *)malloc(sizeof(ChainNode));
    node->cust_idx = cust_idx;
    node->next = table[h];
    table[h] = node;
    int len = 0;
    ChainNode *p = table[h];
    while (p) { len++; p = p->next; }
    return len;
}

int ch_find_phone(ChainNode **table, int size, const char *phone, int htype) {
    int h = hash_phone(phone, size, htype);
    ChainNode *p = table[h];
    while (p) {
        if (strcmp(customers[p->cust_idx].phone, phone) == 0)
            return p->cust_idx;
        p = p->next;
    }
    return -1;
}

int ch_find_name(ChainNode **table, int size, const char *name, int htype) {
    int h = hash_name(name, size, htype);
    ChainNode *p = table[h];
    while (p) {
        if (strcmp(customers[p->cust_idx].name, name) == 0)
            return p->cust_idx;
        p = p->next;
    }
    return -1;
}

/* ===================== 构建所有哈希表 ===================== */

HashStats build_phone_oa(OASlot *table, int size, int htype) {
    oa_init(table, size);
    HashStats s = {0, 0, 0};
    for (int i = 0; i < cust_cnt; i++) {
        int probe = oa_insert_phone(table, size, i, htype);
        s.total_probe += probe;
        if (probe > 1) s.collisions++;
        s.inserted++;
    }
    return s;
}

HashStats build_name_oa(OASlot *table, int size, int htype) {
    oa_init(table, size);
    HashStats s = {0, 0, 0};
    for (int i = 0; i < cust_cnt; i++) {
        int probe = oa_insert_name(table, size, i, htype);
        s.total_probe += probe;
        if (probe > 1) s.collisions++;
        s.inserted++;
    }
    return s;
}

HashStats build_phone_ch(ChainNode **table, int size, int htype) {
    ch_free(table, size);
    HashStats s = {0, 0, 0};
    for (int i = 0; i < cust_cnt; i++) {
        int len = ch_insert_phone(table, size, i, htype);
        s.total_probe += len;
        if (len > 1) s.collisions++;
        s.inserted++;
    }
    return s;
}

HashStats build_name_ch(ChainNode **table, int size, int htype) {
    ch_free(table, size);
    HashStats s = {0, 0, 0};
    for (int i = 0; i < cust_cnt; i++) {
        int len = ch_insert_name(table, size, i, htype);
        s.total_probe += len;
        if (len > 1) s.collisions++;
        s.inserted++;
    }
    return s;
}

/* ===================== 功能函数 ===================== */

/* 功能2：查找聊天狂人 */
void find_maniac(void) {
    count_calls();
    int best = 0;
    for (int i = 1; i < cust_cnt; i++)
        if (customers[i].call_count > customers[best].call_count) best = i;
    printf("\n====== 聊天狂人 ======\n");
    printf("  手机号: %s\n", customers[best].phone);
    printf("  姓  名: %s\n", customers[best].name);
    printf("  通话次数: %d\n\n", customers[best].call_count);
}

/* 功能3：按姓名查找 */
void find_by_name(const char *name) {
    int idx = ch_find_name(name_ch, NAME_TABLE_SIZE, name, HASH_DIV);
    if (idx < 0) {
        printf("No Info\n\n");
        return;
    }
    printf("\n====== 查询结果 ======\n");
    printf("  姓  名: %s\n", customers[idx].name);
    printf("  身份证: %s\n", customers[idx].id);
    printf("  手机号: %s\n", customers[idx].phone);
    printf("  通话记录（共 %d 次）:\n", customers[idx].call_count);
    int printed = 0;
    for (int k = 0; k < call_cnt; k++) {
        if (strcmp(customers[idx].phone, call_from[k]) == 0) {
            printf("    [拨出] -> %s\n", call_to[k]);
            printed++;
        }
        if (strcmp(customers[idx].phone, call_to[k]) == 0) {
            printf("    [接收] <- %s\n", call_from[k]);
            printed++;
        }
    }
    if (!printed) printf("    (无通话记录)\n");
    printf("\n");
}

/* 功能4：冲突率比较 */
void compare_hash_functions(void) {
    printf("\n====== 哈希函数冲突率比较 ======\n");
    printf("数据量=%d，表大小=%d\n\n", cust_cnt, PHONE_TABLE_SIZE);

    OASlot tmp_oa[PHONE_TABLE_SIZE];

    HashStats s_div  = build_phone_oa(tmp_oa, PHONE_TABLE_SIZE, HASH_DIV);
    HashStats s_fold = build_phone_oa(tmp_oa, PHONE_TABLE_SIZE, HASH_FOLD);

    printf("[手机号哈希表 - 开放寻址]\n");
    printf("  %-10s  冲突数=%d  冲突率=%.2f%%\n",
           "除留余数", s_div.collisions,
           100.0 * s_div.collisions / s_div.inserted);
    printf("  %-10s  冲突数=%d  冲突率=%.2f%%\n\n",
           "折叠法", s_fold.collisions,
           100.0 * s_fold.collisions / s_fold.inserted);

    OASlot tmp_oa2[NAME_TABLE_SIZE];
    HashStats sn_div  = build_name_oa(tmp_oa2, NAME_TABLE_SIZE, HASH_DIV);
    HashStats sn_fold = build_name_oa(tmp_oa2, NAME_TABLE_SIZE, HASH_FOLD);

    printf("[姓名哈希表 - 开放寻址]\n");
    printf("  %-10s  冲突数=%d  冲突率=%.2f%%\n",
           "除留余数", sn_div.collisions,
           100.0 * sn_div.collisions / sn_div.inserted);
    printf("  %-10s  冲突数=%d  冲突率=%.2f%%\n\n",
           "折叠法", sn_fold.collisions,
           100.0 * sn_fold.collisions / sn_fold.inserted);
}

/* 功能5：平均查找长度比较 */
void compare_collision_methods(void) {
    printf("\n====== 冲突处理方法对比（ASL）======\n");
    printf("哈希函数=除留余数法，数据量=%d\n\n", cust_cnt);

    OASlot  p_oa[PHONE_TABLE_SIZE];
    ChainNode *p_ch[PHONE_TABLE_SIZE];

    HashStats s_oa = build_phone_oa(p_oa, PHONE_TABLE_SIZE, HASH_DIV);
    HashStats s_ch = build_phone_ch(p_ch, PHONE_TABLE_SIZE, HASH_DIV);

    printf("[手机号哈希表]\n");
    printf("  线性探测开放寻址: 总探测=%ld  ASL=%.2f\n",
           s_oa.total_probe, (double)s_oa.total_probe / s_oa.inserted);
    printf("  链  地  址  法:   总探测=%ld  ASL=%.2f\n\n",
           s_ch.total_probe, (double)s_ch.total_probe / s_ch.inserted);

    OASlot  n_oa[NAME_TABLE_SIZE];
    ChainNode *n_ch[NAME_TABLE_SIZE];

    HashStats sn_oa = build_name_oa(n_oa, NAME_TABLE_SIZE, HASH_DIV);
    HashStats sn_ch = build_name_ch(n_ch, NAME_TABLE_SIZE, HASH_DIV);

    printf("[姓名哈希表]\n");
    printf("  线性探测开放寻址: 总探测=%ld  ASL=%.2f\n",
           sn_oa.total_probe, (double)sn_oa.total_probe / sn_oa.inserted);
    printf("  链  地  址  法:   总探测=%ld  ASL=%.2f\n\n",
           sn_ch.total_probe, (double)sn_ch.total_probe / sn_ch.inserted);

    ch_free(p_ch, PHONE_TABLE_SIZE);
    ch_free(n_ch, NAME_TABLE_SIZE);
}

/* ===================== 按手机号查找 ===================== */
void find_by_phone(const char *phone) {
    int idx = ch_find_phone(phone_ch, PHONE_TABLE_SIZE, phone, HASH_DIV);
    if (idx < 0) {
        printf("No Info\n\n");
        return;
    }
    printf("\n====== 查询结果 ======\n");
    printf("  姓  名: %s\n", customers[idx].name);
    printf("  身份证: %s\n", customers[idx].id);
    printf("  手机号: %s\n", customers[idx].phone);
    printf("  通话次数: %d\n\n", customers[idx].call_count);
}

/* ===================== 主菜单 ===================== */
void print_menu(void) {
    printf("+----------------------------------------+\n");
    printf("|   电话[聊天狂人]查询系统               |\n");
    printf("+----------------------------------------+\n");
    printf("|  1. 查询[聊天狂人](通话次数最多者)    |\n");
    printf("|  2. 按姓名查询用户信息与通话记录       |\n");
    printf("|  3. 按手机号查询用户信息               |\n");
    printf("|  4. 比较两种哈希函数的冲突率           |\n");
    printf("|  5. 比较两种冲突处理方法的ASL          |\n");
    printf("|  0. 退出                               |\n");
    printf("+----------------------------------------+\n");
    printf("请输入操作编号: ");
}
