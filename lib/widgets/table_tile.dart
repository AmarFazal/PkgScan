import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class TableTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String image;
  final String lot;
  final String scrapeStatus;
  final VoidCallback onSwipe; // Sağa kaydırma işlemi için callback
  final bool isLoading;
  final Widget quickEditWidget;

  const TableTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.image,
    required this.lot,
    required this.scrapeStatus,
    required this.onSwipe, required this.isLoading, required this.quickEditWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 0, left: 20, right: 20),
      child: Dismissible(
        key: ValueKey(title), // Benzersiz bir anahtar
        direction: DismissDirection.endToStart, // Sadece sağa kaydırma
        confirmDismiss: (direction) async {
          // Silmeyi engelleyip sadece işlemi tetikler
          if (direction == DismissDirection.endToStart) {
            onSwipe(); // Callback çağrılır
          }
          return false; // Widget silinmez
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.red, // Arka plan rengi
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 30,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: scrapeStatus == 'Scrape Successful'
                ? AppColors.successColor.withOpacity(0.5)
                : scrapeStatus == 'Scrape Failed'
                ? AppColors.errorColor.withOpacity(0.4)
                : scrapeStatus == 'Scrape Successful, Alternate Data Available'
                ? AppColors.successColor.withOpacity(0.7)
                : scrapeStatus == 'Manual Entry Data Scraped'
                ? AppColors.blue.withOpacity(0.4)
                : scrapeStatus == 'Processing...'
                ? AppColors.successColor.withOpacity(0.3)
                : AppColors.secondaryColor,
          ),
          child: isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              :Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              quickEditWidget,
              SizedBox(width: 16),
              // Resim
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  image,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              // Başlık ve alt başlık
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displayMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Alt başlık
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.displaySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                lot,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Icon(
                Icons.navigate_next_rounded,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
