import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class TableTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String image;
  final String lot;
  final String scrapeStatus;
  final VoidCallback onSwipeLeft; // Sola kaydırma işlemi
  final VoidCallback? onSwipeRight; // Sağa kaydırma işlemi
  final bool isLoading;

  const TableTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.image,
    required this.lot,
    required this.scrapeStatus,
    required this.onSwipeLeft,
    this.onSwipeRight,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 0, left: 20, right: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Dismissible(
          key: ValueKey(title), // Benzersiz bir anahtar
          direction: onSwipeRight == null
              ? DismissDirection.endToStart // Sadece sola kaydırma
              : DismissDirection.horizontal, // Hem sağa hem sola kaydırma
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              onSwipeLeft(); // Sola kaydırılınca çağrılır
            } else if (direction == DismissDirection.startToEnd && onSwipeRight != null) {
              onSwipeRight!(); // Sağa kaydırılınca çağrılır
            }
            return false; // Widget silinmez
          },


          background: onSwipeRight != null
              ? Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.blue, // Sağa kaydırma arka planı (örneğin onay)
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 30,
            ),
          )
              : SizedBox(), // Eğer sağa kaydırma yoksa null yap


          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red, // Sola kaydırma arka planı (örneğin silme)
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
              color: scrapeStatus == 'Customer Updated'
                  ? Colors.yellow.withOpacity(0.5)
                  :  scrapeStatus == 'Scrape Successful'
                  ? AppColors.successColor.withOpacity(0.5)
                  : scrapeStatus == 'Scrape Failed'
                  ? AppColors.errorColor.withOpacity(0.4)
                  : scrapeStatus == 'Scrape Successful, Alternate Data Available'
                  ? AppColors.successColor.withOpacity(0.7)
                  : scrapeStatus == 'Manual Entry Data Scraped'
                  ? AppColors.blue.withOpacity(0.4)
                  : scrapeStatus == 'Processing...'
                  ? AppColors.successColor.withOpacity(0.3)
                  : scrapeStatus == 'MSRP ESTIMATED'
                  ? AppColors.darkBlue.withOpacity(0.3)
                  : AppColors.secondaryColor,
            ),
            child: isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.displayMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
      ),
    );
  }
}
