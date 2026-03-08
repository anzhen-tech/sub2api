<template>
  <div class="card p-4">
    <h3 class="mb-4 text-sm font-semibold text-gray-900 dark:text-white">
      {{ title }}
    </h3>
    <div v-if="loading" class="flex h-48 items-center justify-center">
      <LoadingSpinner />
    </div>
    <div v-else-if="trends.length > 0 && chartData" class="h-48">
      <Line :data="chartData" :options="lineOptions" />
    </div>
    <div
      v-else
      class="flex h-48 items-center justify-center text-sm text-gray-500 dark:text-gray-400"
    >
      {{ t('usage.charts.noData') }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { Line } from 'vue-chartjs'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import type { APIKeyTrendItem } from '@/api/usage'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

const { t } = useI18n()

const props = defineProps<{
  trends: APIKeyTrendItem[]
  metric: 'requests' | 'total_tokens' | 'actual_cost'
  title: string
  loading?: boolean
}>()

// Preset color palette for API Key lines
const PRESET_COLORS = [
  '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6',
  '#06b6d4', '#ec4899', '#f97316', '#14b8a6', '#6366f1',
  '#84cc16', '#a855f7', '#0ea5e9', '#d946ef', '#22c55e'
]

const isDarkMode = computed(() => {
  return document.documentElement.classList.contains('dark')
})

const chartColors = computed(() => ({
  text: isDarkMode.value ? '#e5e7eb' : '#374151',
  grid: isDarkMode.value ? '#374151' : '#e5e7eb'
}))

const chartData = computed(() => {
  if (!props.trends?.length) return null

  // Collect all unique dates across all API Keys
  const dateSet = new Set<string>()
  for (const item of props.trends) {
    for (const point of item.data) {
      dateSet.add(point.date)
    }
  }
  const labels = Array.from(dateSet).sort()

  // Build one dataset per API Key
  const datasets = props.trends.map((item, index) => {
    const color = PRESET_COLORS[index % PRESET_COLORS.length]
    // Map data to match sorted labels
    const dataMap = new Map(item.data.map((p) => [p.date, p]))
    const data = labels.map((date) => {
      const point = dataMap.get(date)
      return point ? point[props.metric] : 0
    })

    return {
      label: item.api_key_name || `Key #${item.api_key_id}`,
      data,
      borderColor: color,
      backgroundColor: `${color}15`,
      fill: false,
      tension: 0.3,
      borderWidth: 2,
      pointRadius: 2
    }
  })

  return { labels, datasets }
})

const isCostMetric = computed(() => props.metric === 'actual_cost')

const lineOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  interaction: {
    intersect: false,
    mode: 'index' as const
  },
  plugins: {
    legend: {
      position: 'top' as const,
      labels: {
        color: chartColors.value.text,
        usePointStyle: true,
        pointStyle: 'circle',
        padding: 15,
        font: {
          size: 11
        }
      }
    },
    tooltip: {
      callbacks: {
        label: (context: any) => {
          const value = isCostMetric.value
            ? `$${formatCost(context.raw)}`
            : formatNumber(context.raw)
          return `${context.dataset.label}: ${value}`
        }
      }
    }
  },
  scales: {
    x: {
      grid: {
        color: chartColors.value.grid
      },
      ticks: {
        color: chartColors.value.text,
        font: { size: 10 }
      }
    },
    y: {
      grid: {
        color: chartColors.value.grid
      },
      ticks: {
        color: chartColors.value.text,
        font: { size: 10 },
        callback: (value: string | number) =>
          isCostMetric.value
            ? `$${formatCost(Number(value))}`
            : formatNumber(Number(value))
      }
    }
  }
}))

const formatNumber = (value: number): string => {
  if (value >= 1_000_000_000) return `${(value / 1_000_000_000).toFixed(2)}B`
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(2)}M`
  if (value >= 1_000) return `${(value / 1_000).toFixed(2)}K`
  return value.toLocaleString()
}

const formatCost = (value: number): string => {
  if (value >= 1000) return (value / 1000).toFixed(2) + 'K'
  if (value >= 1) return value.toFixed(2)
  if (value >= 0.01) return value.toFixed(3)
  return value.toFixed(4)
}
</script>
