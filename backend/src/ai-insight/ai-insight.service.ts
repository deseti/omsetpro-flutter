import { Injectable } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { PrismaService } from '../prisma.service';
import { AiInsightQueryDto, AiInsightResponseDto } from './dto/ai-insight.dto';

@Injectable()
export class AiInsightService {
  private genAI: GoogleGenerativeAI;
  private model: any;

  constructor(private prisma: PrismaService) {
    // Initialize Google Gemini AI
    const apiKey = process.env.GEMINI_API_KEY || 'your-gemini-api-key-here';
    this.genAI = new GoogleGenerativeAI(apiKey);
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });
  }

  async processQuery(
    query: AiInsightQueryDto,
    userId: number,
  ): Promise<AiInsightResponseDto> {
    try {
      // 1. Get user context and permissions
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        include: { cabang: true },
      });

      if (!user) {
        throw new Error('User not found');
      }

      // 2. Analyze query intent and extract relevant data
      const businessData = await this.gatherBusinessData(query, user);
      
      // 3. Create AI prompt with business context
      const aiPrompt = this.createBusinessPrompt(query.query, businessData);
      
      // 4. Get AI insight from Gemini
      const result = await this.model.generateContent(aiPrompt);
      const aiResponse = result.response.text();

      // 5. Parse and enhance AI response
      const parsedResponse = this.parseAiResponse(aiResponse, businessData);

      return {
        insight: parsedResponse.insight,
        data: parsedResponse.data,
        suggestions: parsedResponse.suggestions,
        chartData: parsedResponse.chartData,
        confidence: parsedResponse.confidence,
      };
    } catch (error) {
      console.error('AI Insight Error:', error);
      return {
        insight: 'Maaf, saya tidak dapat memproses permintaan Anda saat ini. Silakan coba lagi nanti.',
        suggestions: [
          'Coba tanyakan tentang penjualan hari ini',
          'Tanyakan produk terlaris bulan ini', 
          'Lihat laporan laba rugi minggu ini',
        ],
      };
    }
  }

  private async gatherBusinessData(
    query: AiInsightQueryDto,
    user: any,
  ): Promise<any> {
    const startDate = query.startDate ? new Date(query.startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // 30 days ago
    const endDate = query.endDate ? new Date(query.endDate) : new Date();
    
    // Determine cabang filter based on user role and query
    let cabangFilter = {};
    if (user.role === 'KASIR' && user.aksesCabang?.length > 0) {
      cabangFilter = { cabangId: { in: user.aksesCabang.map(akses => akses.cabangId) } };
    } else if (query.cabangId) {
      cabangFilter = { cabangId: query.cabangId };
    }

    // Gather comprehensive business data
    const [
      salesSummary,
      topProducts,
      transactionStats,
      profitLoss,
      recentTransactions,
      productInventory,
    ] = await Promise.all([
      // Sales summary
      this.prisma.transaksi.aggregate({
        where: {
          createdAt: { gte: startDate, lte: endDate },
          ...cabangFilter,
        },
        _sum: { total: true },
        _count: true,
      }),

      // Top selling products
      this.prisma.transaksiDetail.groupBy({
        by: ['produkId'],
        where: {
          transaksi: {
            createdAt: { gte: startDate, lte: endDate },
            ...cabangFilter,
          },
        },
        _sum: { jumlah: true, hargaSaatItu: true },
        orderBy: { _sum: { jumlah: 'desc' } },
        take: 10,
      }).then(async (results) => {
        return Promise.all(
          results.map(async (item) => {
            const produk = await this.prisma.produk.findUnique({
              where: { id: item.produkId },
            });
            return {
              ...item,
              produk,
              totalRevenue: (item._sum.hargaSaatItu || 0) * (item._sum.jumlah || 0),
            };
          }),
        );
      }),

      // Transaction statistics
      this.prisma.transaksi.groupBy({
        by: ['createdAt'],
        where: {
          createdAt: { gte: startDate, lte: endDate },
          ...cabangFilter,
        },
        _sum: { total: true },
        _count: true,
        orderBy: { createdAt: 'asc' },
      }),

      // Profit/Loss calculation
      this.prisma.transaksiDetail.aggregate({
        where: {
          transaksi: {
            createdAt: { gte: startDate, lte: endDate },
            ...cabangFilter,
          },
        },
        _sum: {
          hargaSaatItu: true,
          jumlah: true,
        },
      }).then(async (result) => {
        // Get detailed profit calculation
        const detailTransaksi = await this.prisma.transaksiDetail.findMany({
          where: {
            transaksi: {
              createdAt: { gte: startDate, lte: endDate },
              ...cabangFilter,
            },
          },
          include: { produk: true },
        });

        const totalRevenue = detailTransaksi.reduce((sum, detail) => {
          return sum + (detail.hargaSaatItu * detail.jumlah);
        }, 0);
        
        const totalCost = detailTransaksi.reduce((sum, detail) => {
          return sum + (detail.jumlah * (detail.produk.hargaBeli || 0));
        }, 0);
        
        return {
          revenue: totalRevenue,
          cost: totalCost,
          profit: totalRevenue - totalCost,
          margin: totalRevenue > 0 ? ((totalRevenue - totalCost) / totalRevenue) * 100 : 0,
        };
      }),

      // Recent transactions
      this.prisma.transaksi.findMany({
        where: {
          createdAt: { gte: startDate, lte: endDate },
          ...cabangFilter,
        },
        include: { 
          cabang: true,
          kasir: { select: { namaLengkap: true } },
          detail: { include: { produk: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 5,
      }),

      // Product inventory
      this.prisma.produk.findMany({
        where: {
          isArsip: false,
          ...(user.role === 'KASIR' && user.aksesCabang?.length > 0 
            ? { cabangId: { in: user.aksesCabang.map(akses => akses.cabangId) } }
            : {}),
        },
        orderBy: { stok: 'asc' },
        take: 10,
      }),
    ]);

    return {
      dateRange: { startDate, endDate },
      salesSummary,
      topProducts,
      transactionStats,
      profitLoss,
      recentTransactions,
      productInventory,
      user: {
        role: user.role,
        cabang: user.cabang,
      },
    };
  }

  private createBusinessPrompt(userQuery: string, businessData: any): string {
    const { dateRange, salesSummary, topProducts, transactionStats, profitLoss, productInventory } = businessData;
    
    return `
Anda adalah asisten AI untuk aplikasi POS (Point of Sale) bernama OmsetPro. 
Anda membantu pemilik bisnis menganalisis data penjualan dan memberikan insight bisnis yang valuable.

KONTEKS BISNIS:
- Periode analisis: ${dateRange.startDate.toLocaleDateString('id-ID')} - ${dateRange.endDate.toLocaleDateString('id-ID')}
- Total penjualan: Rp ${salesSummary._sum.total?.toLocaleString('id-ID') || 0}
- Jumlah transaksi: ${salesSummary._count || 0}
- Total revenue: Rp ${profitLoss.revenue.toLocaleString('id-ID')}
- Total profit: Rp ${profitLoss.profit.toLocaleString('id-ID')}
- Profit margin: ${profitLoss.margin.toFixed(2)}%

PRODUK TERLARIS:
${topProducts.slice(0, 5).map((p, i) => 
  `${i + 1}. ${p.produk?.nama || 'Unknown'}: ${p._sum.jumlah} terjual (Rp ${p.totalRevenue?.toLocaleString('id-ID')})`
).join('\n')}

STOK RENDAH:
${productInventory.slice(0, 5).map((p, i) => 
  `${i + 1}. ${p.nama}: ${p.stok} tersisa`
).join('\n')}

PERTANYAAN USER: "${userQuery}"

INSTRUKSI:
1. Jawab dalam bahasa Indonesia yang natural dan mudah dipahami
2. Berikan insight yang actionable dan specific
3. Gunakan data yang tersedia untuk mendukung jawaban
4. Berikan rekomendasi praktis jika relevan
5. Format response dalam JSON dengan struktur:
{
  "insight": "jawaban utama",
  "data": { data pendukung jika ada },
  "suggestions": ["saran 1", "saran 2", "saran 3"],
  "confidence": 0.95
}

Pastikan insight Anda membantu dalam pengambilan keputusan bisnis!
`;
  }

  private parseAiResponse(aiResponse: string, businessData: any): any {
    try {
      // Try to parse JSON response from AI
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return {
          insight: parsed.insight || aiResponse,
          data: parsed.data || this.generateChartData(businessData),
          suggestions: parsed.suggestions || this.generateDefaultSuggestions(),
          chartData: this.generateChartData(businessData),
          confidence: parsed.confidence || 0.8,
        };
      }
    } catch (error) {
      console.log('Failed to parse AI JSON response, using fallback');
    }

    // Fallback: use raw response
    return {
      insight: aiResponse,
      data: this.generateChartData(businessData),
      suggestions: this.generateDefaultSuggestions(),
      chartData: this.generateChartData(businessData),
      confidence: 0.7,
    };
  }

  private generateChartData(businessData: any): any {
    const { transactionStats, topProducts, profitLoss } = businessData;

    return {
      dailySales: transactionStats.map(stat => ({
        date: stat.createdAt.toISOString().split('T')[0],
        revenue: stat._sum.total || 0,
        transactions: stat._count || 0,
      })),
      topProducts: topProducts.slice(0, 5).map(p => ({
        name: p.produk?.nama || 'Unknown',
        sold: p._sum.jumlah || 0,
        revenue: p.totalRevenue || 0,
      })),
      profitOverview: {
        revenue: profitLoss.revenue,
        cost: profitLoss.cost,
        profit: profitLoss.profit,
        margin: profitLoss.margin,
      },
    };
  }

  private generateDefaultSuggestions(): string[] {
    return [
      'Tanyakan tentang penjualan hari ini',
      'Analisis produk terlaris bulan ini',
      'Lihat tren penjualan minggu ini',
      'Cek stok produk yang perlu diisi ulang',
      'Bandingkan performa antar cabang',
    ];
  }

  async getChatHistory(userId: number, limit: number = 10): Promise<any[]> {
    // For now, return empty array. In production, you'd store chat history in database
    return [];
  }

  async saveChatHistory(userId: number, query: string, response: string): Promise<void> {
    // For now, just log. In production, save to database
    console.log(`Chat saved for user ${userId}: ${query.substring(0, 50)}...`);
  }
}
