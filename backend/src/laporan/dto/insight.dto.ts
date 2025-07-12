export interface InsightCardDto {
  id: string;
  title: string;
  value: string | number;
  trend: 'up' | 'down' | 'stable';
  trendPercentage: number;
  description: string;
  type: 'info' | 'success' | 'warning' | 'danger';
  icon: string;
}

export interface SalesComparisonDto {
  currentPeriod: {
    value: number;
    label: string;
    startDate: string;
    endDate: string;
  };
  previousPeriod: {
    value: number;
    label: string;
    startDate: string;
    endDate: string;
  };
  comparison: {
    percentage: number;
    trend: 'up' | 'down' | 'stable';
    description: string;
  };
}

export interface ProductInsightDto {
  topProduct: {
    name: string;
    sales: number;
    percentage: number;
  };
  risingProduct: {
    name: string;
    growthPercentage: number;
  } | null;
  decliningProduct: {
    name: string;
    declinePercentage: number;
  } | null;
}

export interface ProfitInsightDto {
  currentProfit: number;
  previousProfit: number;
  profitMargin: number;
  comparison: {
    percentage: number;
    trend: 'up' | 'down' | 'stable';
    description: string;
  };
}

export interface TrendDataDto {
  date: string;
  sales: number;
  transactions: number;
  profit: number;
}

export interface InsightDashboardDto {
  insights: InsightCardDto[];
  salesComparison: SalesComparisonDto;
  productInsights: ProductInsightDto;
  profitInsights: ProfitInsightDto;
  trendData: TrendDataDto[];
  lastUpdated: string;
}

export interface GetInsightDto {
  cabangId?: number;
  period: 'daily' | 'weekly' | 'monthly' | 'yearly';
  comparisonPeriod?: 'previous' | 'last_year';
}
